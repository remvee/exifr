GEOTIFF_KEY_IDS = {
  1024 => "GTModelTypeGeoKey",
  1025 => "GTRasterTypeGeoKey",
  1026 => "GTCitationGeoKey",
  2048 => "GeographicTypeGeoKey",
  2049 => "GeogCitationGeoKey",
  2050 => "GeogGeodeticDatumGeoKey",
  2051 => "GeogPrimeMeridianGeoKey",
  2052 => "GeogLinearUnitsGeoKey",
  2053 => "GeogLinearUnitSizeGeoKey",
  2054 => "GeogAngularUnitsGeoKey",
  2055 => "GeogAngularUnitSizeGeoKey",
  2056 => "GeogEllipsoidGeoKey",
  2057 => "GeogSemiMajorAxisGeoKey",
  2058 => "GeogSemiMinorAxisGeoKey",
  2059 => "GeogInvFlatteningGeoKey",
  2060 => "GeogAzimuthUnitsGeoKey",
  2061 => "GeogPrimeMeridianLongGeoKey",
  3072 => "ProjectedCSTypeGeoKey",
  3073 => "PCSCitationGeoKey",
  3074 => "ProjectionGeoKey",
  3075 => "ProjCoordTransGeoKey",
  3076 => "ProjLinearUnitsGeoKey",
  3077 => "ProjLinearUnitSizeGeoKey",
  3078 => "ProjStdParallelGeoKey",
  3079 => "ProjStdParallel2GeoKey",
  3080 => "ProjOriginLongGeoKey",
  3081 => "ProjOriginLatGeoKey",
  3082 => "ProjFalseEastingGeoKey",
  3083 => "ProjFalseNorthingGeoKey",
  3084 => "ProjFalseOriginLongGeoKey",
  3085 => "ProjFalseOriginLatGeoKey",
  3086 => "ProjFalseOriginEastingGeoKey",
  3087 => "ProjFalseOriginNorthingGeoKey",
  3088 => "ProjCenterLongGeoKey",
  3089 => "ProjCenterLatGeoKey",
  3090 => "ProjCenterEastingGeoKey",
  3091 => "ProjFalseOriginNorthingGeoKey",
  3092 => "ProjScaleAtOriginGeoKey",
  3093 => "ProjScaleAtCenterGeoKey",
  3094 => "ProjAzimuthAngleGeoKey",
  3095 => "ProjStraightVertPoleLongGeoKey",
  4096 => "VerticalCSTypeGeoKey",
  4097 => "VerticalCitationGeoKey",
  4098 => "VerticalDatumGeoKey",
  4099 => "VerticalUnitsGeoKey",
}

module EXIFR
  module GeoTIFFParser
    # Return a hash of geotiff keys to values
    def geotiff
      key_directory = geo_key_directory
      double_params = geo_double_params
      ascii_parmas = geo_ascii_params
      if key_directory.length < 4
        return {}
      end

      # Parse the first four header entries
      # key_directory_version = key_directory[0]
      # key_revision = key_directory[1]
      # minor_revision = key_directory[2]
      number_of_keys = key_directory[3]

      if (1 + number_of_keys) * 4 != key_directory.length
        throw "Malformed GeoKeyDirectoryTag"
      end

      params = {}
      (4...key_directory.length).step(4) do |i|
        # The directory entries come in groups of 4
        key = GEOTIFF_KEY_IDS[key_directory[i]]
        location = key_directory[i + 1]
        count = key_directory[i + 2]
        offset = key_directory[i + 3]
        if location == 0
          # A SHORT value, use the offset directly
          params[key] = offset
        elsif location == 0x87b0
          # A double value, use the geo_double_params tag
          if count == 1
            params[key] = double_params[offset]
          else
            params[key] = double_params[offset...offset + count]
          end
        elsif location == 0x87b1
          # An ascii value, use the geo_ascii_params tag
          # Strip the final character since we don't need to add a null
          params[key] = ascii_parmas[offset...offset + count - 1]
        end
      end

      return params
    end
  end
end
