# Copyright (c) 2006 - R.W. van 't Veer

require 'rational'

module EXIFR
  # = JPEG decoder
  #
  # JPEG decoder to read image meta data.
  #
  # == Examples
  #   JPEG.new('IMG_3422.JPG').width         # -> 2272
  #   JPEG.new('IMG_3422.JPG').exif.model    # -> "Canon PowerShot G3"
  class JPEG
    # image height
    attr_reader :height
    # image width
    attr_reader :width
    # number of bits per ???
    attr_reader :bits
    # image comment
    attr_reader :comment
    # hash of exif data if available
    attr_reader :exif

    # +file+ is a filename or an IO object
    def initialize(file)
      if file.kind_of? IO
        examine(file)
      else
        File.open(file, 'rb') { |io| examine(io) }
      end
    end

    # returns +true+ when EXIF data is available
    def exif?
      !exif.nil?
    end

  private
    def examine(io)
      raise 'malformed JPEG' unless io.getc == 0xFF && io.getc == 0xD8 # SOI

      class << io
        def readint; (readchar << 8) + readchar; end
        def readframe; read(readint - 2); end
        def readsof; [readint, readchar, readint, readint, readchar]; end
        def next
          c = readchar while c != 0xFF
          c = readchar while c == 0xFF
          c
        end
      end

      while marker = io.next
        case marker
          when 0xC0..0xC3, 0xC5..0xC7, 0xC9..0xCB, 0xCD..0xCF # SOF markers
            length, @bits, @height, @width, components = io.readsof
            raise 'malformed JPEG' unless length == 8 + components * 3
          when 0xD9, 0xDA:  break # EOI, SOS
          when 0xFE:        @comment = io.readframe # COM
          when 0xE1:        app1 = io.readframe # APP1, contains EXIF tag
          else              io.readframe # ignore frame
        end
      end

      if app1 && EXIF
        @exif = EXIF.new(app1[6..-1]) # rescue nil
      end
    end
  end
end