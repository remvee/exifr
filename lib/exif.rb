#!/usr/bin/env ruby
# Copyright (c) 2006 - R.W. van 't Veer

module EXIFR  
  # = EXIF decoder
  class EXIF < Hash
    TAGS = {
      0x0100 => :image_width,
      0x0101 => :image_length,
      0x0102 => :bits_per_sample,
      0x0103 => :compression,
      0x0106 => :photometric_interpretation,
      0x010a => :fill_order,
      0x010d => :document_name,
      0x010e => :image_description,
      0x010f => :make,
      0x0110 => :model,
      0x0111 => :strip_offsets,
      0x0112 => :orientation,
      0x0115 => :samples_per_pixel,
      0x0116 => :rows_per_strip,
      0x0117 => :strip_byte_counts,
      0x011a => :xresolution,
      0x011b => :yresolution,
      0x011c => :planar_configuration,
      0x0128 => :resolution_unit,
      0x012d => :transfer_function,
      0x0131 => :software,
      0x0132 => :date_time,
      0x013b => :artist,
      0x013e => :white_point,
      0x013f => :primary_chromaticities,
      0x0156 => :transfer_range,
      0x0200 => :jpegproc,
      0x0201 => :jpeginterchange_format,
      0x0202 => :jpeginterchange_format_length,
      0x0211 => :ycb_cr_coefficients,
      0x0212 => :ycb_cr_sub_sampling,
      0x0213 => :ycb_cr_positioning,
      0x0214 => :reference_black_white,
      0x828d => :cfarepeat_pattern_dim,
      0x828e => :cfapattern,
      0x828f => :battery_level,
      0x8298 => :copyright,
      0x829a => :exposure_time,
      0x829d => :fnumber,
      0x83bb => :iptc_naa,
      0x8769 => :exif_offset,
      0x8773 => :inter_color_profile,
      0x8822 => :exposure_program,
      0x8824 => :spectral_sensitivity,
      0x8825 => :gpsinfo,
      0x8827 => :isospeed_ratings,
      0x8828 => :oecf,
      0x9000 => :exif_version,
      0x9003 => :date_time_original,
      0x9004 => :date_time_digitized,
      0x9101 => :components_configuration,
      0x9102 => :compressed_bits_per_pixel,
      0x9201 => :shutter_speed_value,
      0x9202 => :aperture_value,
      0x9203 => :brightness_value,
      0x9204 => :exposure_bias_value,
      0x9205 => :max_aperture_value,
      0x9206 => :subject_distance,
      0x9207 => :metering_mode,
      0x9208 => :light_source,
      0x9209 => :flash,
      0x920a => :focal_length,
      0x9214 => :subject_area,
      0x927c => :maker_note,
      0x9286 => :user_comment,
      0x9290 => :subsec_time,
      0x9291 => :subsec_time_orginal,
      0x9292 => :subsec_time_digitized,
      0xa000 => :flash_pix_version,
      0xa001 => :color_space,
      0xa002 => :pixel_xdimension,
      0xa003 => :pixel_ydimension,
      0xa004 => :related_sound_file,
      0xa005 => :interoperability_offset,
      0xa20b => :flash_energy,
      0xa20c => :spatial_frequency_response,
      0xa20e => :focal_plane_xresolution,
      0xa20f => :focal_plane_yresolution,
      0xa210 => :focal_plane_resolution_unit,
      0xa214 => :subject_location,
      0xa215 => :exposure_index,
      0xa217 => :sensing_method,
      0xa300 => :file_source,
      0xa301 => :scene_type,
      0xa302 => :cfapattern,
      0xa401 => :custom_rendered,
      0xa402 => :exposure_mode,
      0xa403 => :white_balance,
      0xa404 => :digital_zoom_ratio,
      0xa405 => :focal_len_in_35mm_film,
      0xa406 => :scene_capture_type,
      0xa407 => :gain_control,
      0xa408 => :contrast,
      0xa409 => :saturation,
      0xa40a => :sharpness,
      0xa40b => :device_setting_descr,
      0xa40c => :subject_dist_range,
      0xa420 => :image_unique_id
    }
    EXIF_HEADERS = [0x8769, 0x8825, 0xa005]

    time_proc = proc do |value|
      if value =~ /^(\d{4}):(\d\d):(\d\d) (\d\d):(\d\d):(\d\d)$/
        Time.mktime($1, $2, $3, $4, $5, $6)
      else
        value
      end
    end
    
    module TopLeftOrientation
      def self.to_i; 1; end
      def self.to_rmagic_proc; proc { |img| img }; end
    end
    
    module TopRightOrientation
      def self.to_i; 2; end
      def self.to_rmagic_proc; proc { |img| img.flop }; end
    end
    
    module BottomRightOrientation
      def self.to_i; 3; end
      def self.to_rmagic_proc; proc { |img| img.rotate(180) }; end
    end
    
    module BottomLeftOrientation
      def self.to_i; 4; end
      def self.to_rmagic_proc; proc { |img| img.flip }; end
    end
    
    module LeftTopOrientation
      def self.to_i; 5; end
      def self.to_rmagic_proc; proc { |img| img.rotate(90).flop }; end
    end
    
    module RightTopOrientation
      def self.to_i; 6; end
      def self.to_rmagic_proc; proc { |img| img.rotate(90) }; end
    end
    
    module RightBottomOrientation
      def self.to_i; 7; end
      def self.to_rmagic_proc; proc { |img| img.rotate(270).flop }; end
    end
    
    module LeftBottomOrientation
      def self.to_i; 8; end
      def self.to_rmagic_proc; proc { |img| img.rotate(270) }; end    
    end
    
    ORIENTATIONS = [
      nil, TopLeftOrientation, TopRightOrientation, BottomRightOrientation,
      BottomLeftOrientation, LeftTopOrientation, RightTopOrientation,
      RightBottomOrientation, LeftBottomOrientation
    ]
    
    ADAPTERS = Hash.new { proc { |v| v } }
    ADAPTERS.merge!({
      :date_time_original => time_proc,
      :date_time_digitized => time_proc,
      :date_time => time_proc,
      :orientation => proc { |v| ORIENTATIONS[v] }
    })

    # +data+ the content of the JPEG APP1 frame without the EXIF marker
    def initialize(data)
      @data = data
      traverse(TiffHeader.new(@data))
      freeze
    end

    # convience
    def method_missing(method, *args)
      self[method]
    end

  private
    def traverse(tiff)
      tiff.fields.each do |f|
        tag = TAGS[f.tag]
        value = f.value.map { |v| ADAPTERS[tag][v] } if f.value
        value = (value.kind_of?(Array) && value.size == 1) ? value.first : value
        if EXIF_HEADERS.include?(f.tag)
          traverse(TiffHeader.new(@data, f.offset))
        elsif tag
          self[tag] = value
        end
      end
    end
  end
end
