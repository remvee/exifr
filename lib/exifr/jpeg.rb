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
    APP1 = 0xe1 # Probably EXIF (TIFF), or XMP
    APP13 = 0xed # Probably Photoshop (probably containing IPTC)
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

    def xmp?
      !!@xmp_index
    end

    def xmp
      @segments[@xmp_index].xmp if xmp?
    end

    def iptc?
      !!@iptc_index
    end

    def iptc
      @segments[@iptc_index].iptc
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
          when APP13
            logger.debug { "APP13 @ #{start}, #{length} bytes." }
            read_segment_app13(io, length: length)
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
        when XMPSegment::HEADER_MAGIC
          read_segment_xmp(io, length: length)
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

    def read_segment_xmp(io, length:)
      segment = XMPSegment.new(io, length: length)
      logger.debug { "XMP segment: #{segment.inspect}" }
      @xmp_index ||= @segments.length
      @segments << segment
    end

    def read_segment_comment(io, length:)
      segment = CommentSegment.new(io, length: length)
      logger.debug { "Comment segment: #{segment.inspect}" }
      @comment_index ||= @segments.length
      @segments << segment
    end

    def read_segment_app13(io, length:)
      # APP13 segments could be a few different things
      case header = peek(io, 32)
        when PhotoshopSegment::HEADER_MAGIC
          read_segment_photoshop(io, length: length)
        when OldPhotoshopSegment::HEADER_MAGIC
          read_segment_old_photoshop(io, length: length)
        else
          logger.debug { "Unknown APP1 @ #{io.tell}: #{header.inspect}" }
      end
    end

    def read_segment_photoshop(io, length:)
      segment = PhotoshopSegment.new(io, length: length)
      logger.debug { "Photoshop segment: #{segment.inspect}" }
      @iptc_index ||= @segments.length
      @segments << segment
    end

    def read_segment_old_photoshop(io, length:)
      segment = OldPhotoshopSegment.new(io, length: length)
      logger.debug { "Old Photoshop segment: #{segment.inspect}" }
      @iptc_index ||= @segments.length
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

  class JPEG::XMPSegment
    HEADER = "http://ns.adobe.com/xap/1.0/\0"
    HEADER_MAGIC = /\A#{Regexp.escape(HEADER)}/.freeze
    HEADER_SIZE = HEADER.bytesize

    def initialize(io, length:)
      start = io.tell
      header = io.read(HEADER_SIZE)
      unless header == HEADER
        raise MalformedJPEG, "Expected XMP header at byte #{start} but got: #{header.inspect}"
      end

      begin
        require "xmp_fixed"
      rescue LoadError
        EXIFR.logger.warn "EXIFR::JPEG: Install xmp_fixed gem for XMP metadata"
      end

      if defined? XmpFixed
        @xmp = XmpFixed.new(io.read(length))
      end
    end

    def xmp
      @xmp || raise("Install xmp_fixed gem for XMP metadata")
    end
  end

  class JPEG::PhotoshopSegment
    HEADER = "Photoshop 3.0\0".force_encoding("BINARY").freeze
    HEADER_SIZE = HEADER.bytesize
    HEADER_MAGIC = /\A#{Regexp.escape(HEADER)}/.freeze

    IPTC_TYPE = "8BIM".force_encoding("BINARY").freeze
    IPTC_TAG = 0x0404

    attr_reader :iptc

    # Starts with a known header, differs by version
    # Photoshop is always big-endian

    def initialize(io, length:)
      start = io.tell
      finish = start + length

      # Skip header
      io.seek(self.class::HEADER_SIZE, IO::SEEK_CUR)

      until io.eof? || io.tell >= finish
        type = io.read(4)
        tag = io.read(2).unpack("n").first
        name = read_string(io)

        resource_length = io.read(4).unpack("N").first
        resource_start = io.tell
        resource_finish = resource_start + resource_length
        # Photoshop pads things to even bytes.
        if resource_length.odd?
          resource_finish += 1
        end

        EXIFR.logger.debug { "Photoshop Resource Type=#{type.inspect}, Tag=0x#{tag.to_s(16)}, Name=#{name.inspect}, Length=#{resource_length.inspect}" }

        # We only care about IPTC data
        if type == IPTC_TYPE && tag == IPTC_TAG
          @iptc = IPTC.new(io, length: resource_length)
        end

        # Get ready to read the next resource.
        unless io.tell == resource_finish
          io.seek(resource_finish)
        end
      end
    end

    private

    STRING_ENCODING = "ISO-8859-1".freeze # latin, photoshop default
    STRING_NULL = "\x00".force_encoding("BINARY").freeze

    # Photoshop strings are pascal strings:
    #  * 8-bit unsigned length
    #  * a null byte if length is zero
    #  * string blob padded to 2-byte offset
    def read_string(io)
      length = io.readbyte
      io.read(length).force_encoding(STRING_ENCODING).tap do
        if length.zero?
          # Skip expected null byte
          null = io.read(1)
          unless null == STRING_NULL
            raise MalformedJPEG, "Expected null byte for zero-length string, found: #{null.inspect}"
          end
        elsif length.odd?
          # Skip padding byte
          io.seek(1, IO::SEEK_CUR)
        end
      end
    end
  end

  class JPEG::OldPhotoshopSegment
    HEADER = "Adobe_Photoshop2.5:".force_encoding("BINARY").freeze
    HEADER_SIZE = 27
    HEADER_MAGIC = /\A#{Regexp.escape(HEADER)}/.freeze
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
