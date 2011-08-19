# Copyright (c) 2006, 2007, 2008, 2009, 2010, 2011 - R.W. van 't Veer

require 'exifr'
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
    # raw EXIF data
    attr_reader :exif_data # :nodoc:
    # raw APP1 frames
    attr_reader :app1s, :app13s, :values

    # +file+ is a filename or an IO object.  Hint: use StringIO when working with slurped data like blobs.
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

    # Return thumbnail data when available.
    def thumbnail
      @exif && @exif.jpeg_thumbnails && @exif.jpeg_thumbnails.first
    end

    # Get a hash presentation of the image.
    def to_hash
      h = {:width => width, :height => height, :bits => bits, :comment => comment}
      h.merge!(@values) if @values
      h.merge!(exif) if exif?
      h
    end

    # Dispatch to EXIF.  When no EXIF data is available but the
    # +method+ does exist for EXIF data +nil+ will be returned.
    def method_missing(method, *args)
      super unless args.empty?
      super unless methods.include?(method.to_s)
      return @exif.send method if @exif.respond_to? method
      return @values[method] if @values && @values.keys.include?(method)
    end

    def respond_to?(method) # :nodoc:
      super || methods.include?(method.to_s)
    end

    def methods # :nodoc:
      iptc = @values.nil? ? [] : @values.keys.map {|x| x.to_s}
      iptc + super + TIFF::TAGS << "gps"
    end

    class << self
      alias instance_methods_without_jpeg_extras instance_methods
      def instance_methods(include_super = true) # :nodoc:
        instance_methods_without_jpeg_extras(include_super) + TIFF::TAGS << "gps"
      end
    end

  private
    def examine(io)
      class << io
        def readbyte; readchar; end unless method_defined?(:readbyte)
        def readint; (readbyte << 8) + readbyte; end
        def readframe; read(readint - 2); end
        def readsof; [readint, readbyte, readint, readint, readbyte]; end
        def next
          c = readbyte while c != 0xFF
          c = readbyte while c == 0xFF
          c
        end
      end unless io.respond_to? :readsof

      unless io.readbyte == 0xFF && io.readbyte == 0xD8 # SOI
        raise MalformedJPEG, "no start of image marker found"
      end

      @app1s, @app13s = [], []
      while marker = io.next
        case marker
          when 0xC0..0xC3, 0xC5..0xC7, 0xC9..0xCB, 0xCD..0xCF # SOF markers
            length, @bits, @height, @width, components = io.readsof
            unless length == 8 + components * 3
              raise MalformedJPEG, "frame length does not match number of components"
            end
          when 0xD9, 0xDA;  break # EOI, SOS
          when 0xFE;        (@comment ||= []) << io.readframe # COM
          when 0xE1;        @app1s << io.readframe # APP1, may contain EXIF tag
          when 0xED;        @app13s << io.readframe # APP13, may contain IPTC
          else              io.readframe # ignore frame
        end
      end

      @comment = @comment.first if @comment && @comment.size == 1

      if app1 = @app1s.find { |d| d[0..5] == "Exif\0\0" }
        @exif_data = app1[6..-1]
        @exif = TIFF.new(StringIO.new(@exif_data))
      end

      if str = @app13s[0] 
        @tagmap ||= {5=>:object_name, 27=>:location_name, 38=>:expiration_time, 60=>:time_created, 115=>:source, 22=>:fixture_id, 55=>:date_created, 110=>:credit, 154=>:audio_outcue, 50=>:reference_number, 105=>:headline, 116=>:copyright, 12=>:subject, 45=>:reference_service, 100=>:country_code, 122=>:writer, 7=>:edit_status, 40=>:special_instructions, 62=>:digitization_date, 95=>:province_state, 150=>:audio_type, 35=>:release_time, 90=>:city, 101=>:country_name, 200=>:preview_format, 8=>:editorial_update, 30=>:release_date, 63=>:digitization_time, 85=>:byline_title, 118=>:contact, 151=>:audio_rate, 3=>:object_type, 25=>:keywords, 47=>:reference_date, 80=>:byline, 135=>:language, 201=>:preview_version, 20=>:supp_category, 42=>:action_advised, 75=>:object_cycle, 130=>:image_type, 152=>:audio_resolution, 4=>:object_attribute, 15=>:category, 26=>:location_code, 37=>:expiration_date, 70=>:program_version, 92=>:sub_location, 103=>:transmission_reference, 125=>:rasterized_caption, 202=>:preview, 10=>:urgency, 65=>:program, 120=>:caption, 131=>:image_orientation, 153=>:audio_duration}
        # 0=>:record_version, is only needed for internal parsing and can give odd results 
        @values = {}
        stream = str.kind_of?(String) ? StringIO.new(str) : str
        until stream.eof?
          if stream.readchar == 28
             if stream.readchar == 2
               tag_type = @tagmap[stream.readchar.to_i]
               stream.readchar # throwaway value
               length = stream.readchar
               if @values[tag_type]
                 if @values[tag_type].kind_of?(String)
                   @values[tag_type] = [@values[tag_type], stream.read(length)]
                 else
                   @values[tag_type] << stream.read(length)
                 end
               else
                 @values[tag_type] = stream.read(length)
               end
             else
               stream.seek(-1, IO::SEEK_CUR)
             end
          end
        end

      end

    end
  end
end
