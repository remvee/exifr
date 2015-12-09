# Copyright (c) 2006-2015 - R.W. van 't Veer

require "exifr"
require "stringio"
require "delegate"

module EXIFR
  # = JPEG parser
  #
  # Reads a JPEG file and extracts useful metadata.
  #
  # == Examples
  #   EXIFR::JPEG.open("IMG_3422.JPG").width         # -> 2272
  #   EXIFR::JPEG.new(env["rack.input"]).exif.model  # -> "Canon PowerShot G3"
  #
  # == References
  #  * http://www.w3.org/Graphics/JPEG/itu-t81.pdf
  #  * http://www.ozhiker.com/electronics/pjmt/jpeg_info/
  class JPEG
    # JPEG headers are made up of segments. Each segment starts with a marker.
    # Markers are two bytes: 0xff, then one of the following:
    SOFs = [0xc0..0xc3, 0xc5..0xc7, 0xc9..0xcc, 0xce..0xcf] # Start Of Frame
    SOI = 0xd8 # Start Of Image
    EOI = 0xd9 # End Of Image
    SOS = 0xda # Start Of Scan
    APPs = [0xe0..0xef] # Application-use
    APP1 = 0xe1 # Probably EXIF (TIFF)
    COM = 0xfe # Comment

    # Open a file and return parsed metadata.
    def self.open(file)
      File.open(file, "rb") { |io| new(io) }
    end

    # Read an IO object (must be open in binary read mode and seekable) and return parsed metadata.
    def initialize(io)
      @segments = []
      read(io)
    end

    attr_reader :segments

    def sof?
      !!@sof_index
    end

    def bits
      @segments[@sof_index].bits if sof?
    end

    def width
      @segments[@sof_index].width if sof?
    end

    def height
      @segments[@sof_index].height if sof?
    end

    def components
      @segments[@sof_index].components if sof?
    end

    def exif?
      !!@exif_index
    end

    def exif
      @segments[@exif_index].exif if exif?
    end

    def thumbnail
      if exif? && !exif.jpeg_thumbnails.empty?
        exif.jpeg_thumbnails.first
      end
    end

    def comment?
      !!@comment_index
    end

    def comment
      @segments[@comment_index].comment if comment?
    end

  private

    def logger
      EXIFR.logger
    end

    def read(io)
      logger.debug { "Reading #{io.inspect}" }

      # Every JPEG should start with an SOI segment, which has no length.
      unless read_marker(io) == SOI
        raise MalformedJPEG, "no start of image marker found"
      end
      logger.debug { "SOI @ #{io.tell}" }

      # Read segments
      until io.eof?
        # Every segment starts with a marker
        marker = read_marker(io)

        # EOI has no length and signifies file end
        if marker == EOI
          logger.debug { "EOI @ #{io.tell}, done parsing." }
          break
        end

        # SOS is the beginning of picture data, metadata is over
        if marker == SOS
          logger.debug { "SOS @ #{io.tell}, aborting parsing." }
          break
        end

        # Every other marker has a length
        # Length includes the bytes of the length itself, compensate
        length = io.read(2).unpack("S>").first - 2
        start = io.tell
        finish = start + length

        # Do we want to parse this segment?
        case marker
          when *SOFs
            logger.debug { "SOF @ #{start}, #{length} bytes." }
            read_segment_sof(io, length: length)
          when APP1
            logger.debug { "APP1 @ #{start}, #{length} bytes." }
            read_segment_app1(io, length: length)
          when COM
            logger.debug { "Comment @ #{start}, #{length} bytes." }
            read_segment_comment(io, length: length)
          else
            logger.debug { "Unknown segment 0x#{marker.to_s(16)} @ #{start}, #{length} bytes." }
        end

        # Make sure we're at the end of that segment
        unless io.tell == finish
          io.seek(finish)
        end
      end
    end

    def read_length(io)
      (io.readbyte << 8) + io.readbyte
    end

    def read_marker(io)
      # Skip null bytes
      while (byte = io.readbyte) == 0x00; end

      # Markers start with full byte
      unless byte == 0xff
        raise MalformedJPEG, "Expected marker at byte #{io.tell - 1}, got 0x#{byte.to_s(16)}"
      end

      # Then a second byte idenfitying the segment
      io.readbyte
    end

    def read_segment_sof(io, length:)
      segment = SOFSegment.new(io, length: length)
      logger.debug { "SOF segment: #{segment.inspect}" }
      @sof_index ||= @segments.length
      @segments << segment
    end

    def read_segment_app1(io, length:)
      # APP1 segments could be a few different things
      case header = peek(io, 32)
        when EXIFSegment::HEADER_MAGIC
          read_segment_exif(io, length: length)
        else
          logger.debug { "Unknown APP1 @ #{io.tell}: #{header.inspect}" }
      end
    end

    def read_segment_exif(io, length:)
      segment = EXIFSegment.new(io, length: length)
      logger.debug { "EXIF segment: #{segment.inspect}" }
      @exif_index ||= @segments.length
      @segments << segment
    end

    def read_segment_comment(io, length:)
      segment = CommentSegment.new(io, length: length)
      logger.debug { "Comment segment: #{segment.inspect}" }
      @comment_index = @segments.length
      @segments << segment
    end

    def peek(io, length)
      # Ruby doesn't have multi-byte peek, so fake it.
      io.read(length).tap { io.seek(-length, IO::SEEK_CUR) }
    end
  end

  class JPEG::SOFSegment
    attr_reader :bits
    attr_reader :height
    attr_reader :width
    attr_reader :components

    def initialize(io, length:)
      @bits = io.readbyte
      @height = read_int(io)
      @width = read_int(io)
      @components = io.readbyte

      unless length == (6 + @components * 3)
        raise MalformedJPEG, "Frame length does not match number of components"
      end
    end

    private

    def read_int(io)
      io.read(2).unpack("S>").first
    end
  end

  class JPEG::EXIFSegment
    attr_reader :exif

    HEADER = "Exif\0\0".force_encoding("BINARY").freeze
    HEADER_MAGIC = /\A#{Regexp.escape(HEADER)}/.freeze

    def initialize(io, length:)
      start = io.tell
      header = io.read(6)
      unless header == HEADER
        raise MalformedJPEG, "Expected EXIF header at byte #{start} but got: #{header.inspect}"
      end

      @exif = EXIFR::TIFF.new(StringIO.new(io.read(length)))
    end
  end

  class JPEG::CommentSegment
    attr_reader :comment

    def initialize(io, length:)
      @comment = io.read(length)
    end

    def to_s
      comment
    end
  end
end
