# Copyright (c) 2006, 2007 - R.W. van 't Veer

require 'stringio'

module EXIFR
  # = JPEG decoder
  #
  # == Examples
  #   EXIFR::JPEG.new('IMG_3422.JPG').width         # -> 2272
  #   EXIFR::JPEG.new('IMG_3422.JPG').exif.model    # -> "Canon PowerShot G3"
  class JPEG
    # image height
    attr_reader :height
    # image width
    attr_reader :width
    # number of bits per ??
    attr_reader :bits # :nodoc:
    # comment; a string if one comment found, an array if more,
    # otherwise <tt>nil</tt>
    attr_reader :comment
    # EXIF data if available
    attr_reader :exif

    # +file+ is a filename or an IO object.
    def initialize(file)
      if file.kind_of? String
        File.open(file, 'rb') { |io| examine(io) }
      else
        examine(file.dup)
      end
    end

    # Returns +true+ when EXIF data is available.
    def exif?
      !exif.nil?
    end

    # Dispath to EXIF.  When no EXIF data is available but the +method+ does exist
    # for EXIF data +nil+ will be returned.
    def method_missing(method, *args)
      super unless args.empty?
      super unless TIFF::TAGS.include?(method)
      @exif.send method if @exif
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
      end unless io.respond_to? :readsof

      app1s = []
      while marker = io.next
        case marker
          when 0xC0..0xC3, 0xC5..0xC7, 0xC9..0xCB, 0xCD..0xCF # SOF markers
            length, @bits, @height, @width, components = io.readsof
            raise 'malformed JPEG' unless length == 8 + components * 3
          when 0xD9, 0xDA:  break # EOI, SOS
          when 0xFE:        (@comment ||= []) << io.readframe # COM
          when 0xE1:        app1s << io.readframe # APP1, may contain EXIF tag
          else              io.readframe # ignore frame
        end
      end

      @comment = @comment.first if @comment && @comment.size == 1
      
      if app1 = app1s.find { |d| d[0..5] == "Exif\0\0" }
        @exif = TIFF.new(StringIO.new(app1[6..-1]))
      end
    end
  end
end