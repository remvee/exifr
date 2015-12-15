require "exifr"

module EXIFR
  # = IPTC
  #
  # == Notes
  # An IPTC record is a series of records. Records contain datasets. Each
  # dataset contains a data field, which is a particular value for that
  # dataset. Repeated datasets represent mulitple fields for the same dataset,
  # like for list data.
  #
  # == References
  # * https://www.iptc.org/std/photometadata/2008/specification/IPTC-PhotoMetadata-2008.pdf
  # * https://www.iptc.org/std/IIM/4.1/specification/IIMV4.1.pdf
  # * https://en.wikipedia.org/wiki/ISO/IEC_2022#ISO.2FIEC_2022_character_sets
  class IPTC
    attr_reader :fields

    # IPTC IIM specifics the default encoding is ISO646/4873, which is roughly ASCII
    DEFAULT_ENCODING = Encoding::ASCII

    # Descriptions of records and their datasets.
    RECORDS = {
      0x01 => {
        name: 'IPTCEnvelope',
        datasets: {
          0x00 => {
            name: 'EnvelopeRecordVersion',
            type: 'int16u',
          },
          0x05 => {
            name: 'Destination',
            list: true,
            type: 'string',
            size: (0..1024),
          },
          0x14 => {
            name: 'FileFormat',
            type: 'int16u',
          },
          0x16 => {
              name: 'FileVersion',
              type: 'int16u',
          },
          0x1e => {
            name: 'ServiceIdentifier',
            type: 'string',
            size: (0..10),
          },
          0x28 => {
            name: 'EnvelopeNumber',
            type: 'digits',
            size: 8,
          },
          0x32 => {
            name: 'ProductID',
            list: true,
            type: 'string',
            size: (0..32),
          },
          0x3c => {
            name: 'EnvelopePriority',
            type: 'digits',
            size: 1,
            print_conv: {
              0x00 => '0 (reserved)',
              0x01 => '1 (most urgent)',
              0x02 => 2,
              0x03 => 3,
              0x04 => 4,
              0x05 => '5 (normal urgency)',
              0x06 => 6,
              0x07 => 7,
              0x08 => '8 (least urgent)',
              0x09 => '9 (user-defined priority)',
            },
          },
          0x46 => {
              name: 'DateSent',
              type: 'digits',
              size: 8,
              shift: 'Time',
              value_conv: 'Image::ExifTool::Exif::ExifDate($val)',
              value_conv_inv: 'Image::ExifTool::IPTC::IptcDate($val)',
              print_conv_inv: 'Image::ExifTool::IPTC::InverseDateOrTime($val)',
          },
          0x50 => {
              name: 'TimeSent',
              type: 'string',
              size: 11,
              shift: 'Time',
              value_conv: 'Image::ExifTool::Exif::ExifTime($val)',
              value_conv_inv: 'Image::ExifTool::IPTC::IptcTime($val)',
              print_conv_inv: 'Image::ExifTool::IPTC::InverseDateOrTime($val)',
          },
          0x5a => {
              name: 'CodedCharacterSet',
              notes: %{
                  values are entered in the form "ESC X Y[, ...]".  The escape sequence for
                  UTF-8 character coding is "ESC % G", but this is displayed as "UTF8" for
                  convenience.  Either string may be used when writing.  The value of this tag
                  affects the decoding of string values in the Application and NewsPhoto
                  records.  This tag is marked as "unsafe" to prevent it from being copied by
                  default in a group operation because existing tags in the destination image
                  may use a different encoding.  When creating a new IPTC record from scratch,
                  it is suggested that this be set to "UTF8" if special characters are a
                  possibility
              },
              protected: 1,
              type: 'string',
              size: (0..32),
              # convert ISO 2022 escape sequences to a more readable format
              print_conv: 'PrintCodedCharset',
              print_conv_inv: 'PrintInvCodedCharset',
          },
          0x64 => {
              name: 'UniqueObjectName',
              type: 'string',
              size: (14..80),
          },
          0x78 => {
              name: 'ARMIdentifier',
              type: 'int16u',
          },
          0x7a => {
              name: 'ARMVersion',
              type: 'int16u',
          },
        },
      },
      0x02 => {
        name: 'IPTCApplication',
        datasets: {
          0x00 => {
              name: 'ApplicationRecordVersion',
              type: 'int16u',
              mandatory: 1,
          },
          0x03 => {
              name: 'ObjectTypeReference',
              type: 'string',
              size: (3..67),
          },
          0x04 => {
              name: 'ObjectAttributeReference',
              list: true,
              type: 'string',
              size: (4..68),
          },
          0x05 => {
              name: 'ObjectName',
              type: 'string',
              size: (0..64),
          },
          0x07 => {
              name: 'EditStatus',
              type: 'string',
              size: (0..64),
          },
          0x08 => {
              name: 'EditorialUpdate',
              type: 'digits',
              size: 2,
              print_conv: {
                  '01' => 'Additional language',
              },
          },
          0x0a => {
              name: 'Urgency',
              type: 'digits',
              size: 1,
              print_conv: {
                  0x00 => '0 (reserved)',
                  0x01 => '1 (most urgent)',
                  0x02 => 2,
                  0x03 => 3,
                  0x04 => 4,
                  0x05 => '5 (normal urgency)',
                  0x06 => 6,
                  0x07 => 7,
                  0x08 => '8 (least urgent)',
                  0x09 => '9 (user-defined priority)',
              },
          },
          0x0c => {
              name: 'SubjectReference',
              list: true,
              type: 'string',
              size: (13..236),
          },
          0x0f => {
              name: 'Category',
              type: 'string',
              size: (0..3),
          },
          0x14 => {
              name: 'SupplementalCategories',
              list: true,
              type: 'string',
              size: (0..32),
          },
          0x16 => {
              name: 'FixtureIdentifier',
              type: 'string',
              size: (0..32),
          },
          0x19 => {
              name: 'Keywords',
              list: true,
              type: 'string',
              size: (0..64),
          },
          0x1a => {
              name: 'ContentLocationCode',
              list: true,
              type: 'string',
              size: 3,
          },
          0x1b => {
              name: 'ContentLocationName',
              list: true,
              type: 'string',
              size: (0..64),
          },
          0x1e => {
              name: 'ReleaseDate',
              type: 'digits',
              size: 8,
              shift: 'Time',
              value_conv: 'Image::ExifTool::Exif::ExifDate($val)',
              value_conv_inv: 'Image::ExifTool::IPTC::IptcDate($val)',
              print_conv_inv: 'Image::ExifTool::IPTC::InverseDateOrTime($val)',
          },
          0x23 => {
              name: 'ReleaseTime',
              type: 'string',
              size: 11,
              shift: 'Time',
              value_conv: 'Image::ExifTool::Exif::ExifTime($val)',
              value_conv_inv: 'Image::ExifTool::IPTC::IptcTime($val)',
              print_conv_inv: 'Image::ExifTool::IPTC::InverseDateOrTime($val)',
          },
          0x25 => {
              name: 'ExpirationDate',
              type: 'digits',
              size: 8,
              shift: 'Time',
              value_conv: 'Image::ExifTool::Exif::ExifDate($val)',
              value_conv_inv: 'Image::ExifTool::IPTC::IptcDate($val)',
              print_conv_inv: 'Image::ExifTool::IPTC::InverseDateOrTime($val)',
          },
          0x26 => {
              name: 'ExpirationTime',
              type: 'string',
              size: 11,
              shift: 'Time',
              value_conv: 'Image::ExifTool::Exif::ExifTime($val)',
              value_conv_inv: 'Image::ExifTool::IPTC::IptcTime($val)',
              print_conv_inv: 'Image::ExifTool::IPTC::InverseDateOrTime($val)',
          },
          0x28 => {
              name: 'SpecialInstructions',
              type: 'string',
              size: (0..256),
          },
          0x2a => {
              name: 'ActionAdvised',
              type: 'digits',
              size: 2,
              print_conv: {
                  '' => '',
                  '01' => 'Object Kill',
                  '02' => 'Object Replace',
                  '03' => 'Object Append',
                  '04' => 'Object Reference',
              },
          },
          0x2d => {
              name: 'ReferenceService',
              list: true,
              type: 'string',
              size: (0..10),
          },
          0x2f => {
              name: 'ReferenceDate',
              list: true,
              type: 'digits',
              size: 8,
              shift: 'Time',
              value_conv: 'Image::ExifTool::Exif::ExifDate($val)',
              value_conv_inv: 'Image::ExifTool::IPTC::IptcDate($val)',
              print_conv_inv: 'Image::ExifTool::IPTC::InverseDateOrTime($val)',
          },
          0x32 => {
              name: 'ReferenceNumber',
              list: true,
              type: 'digits',
              size: 8,
          },
          0x37 => {
              name: 'DateCreated',
              type: 'digits',
              size: 8,
              shift: 'Time',
              value_conv: 'Image::ExifTool::Exif::ExifDate($val)',
              value_conv_inv: 'Image::ExifTool::IPTC::IptcDate($val)',
              print_conv_inv: 'Image::ExifTool::IPTC::InverseDateOrTime($val)',
          },
          0x3c => {
              name: 'TimeCreated',
              type: 'string',
              size: 11,
              shift: 'Time',
              value_conv: 'Image::ExifTool::Exif::ExifTime($val)',
              value_conv_inv: 'Image::ExifTool::IPTC::IptcTime($val)',
              print_conv_inv: 'Image::ExifTool::IPTC::InverseDateOrTime($val)',
          },
          0x3e => {
              name: 'DigitalCreationDate',
              type: 'digits',
              size: 8,
              shift: 'Time',
              value_conv: 'Image::ExifTool::Exif::ExifDate($val)',
              value_conv_inv: 'Image::ExifTool::IPTC::IptcDate($val)',
              print_conv_inv: 'Image::ExifTool::IPTC::InverseDateOrTime($val)',
          },
          0x3f => {
              name: 'DigitalCreationTime',
              type: 'string',
              size: 11,
              shift: 'Time',
              value_conv: 'Image::ExifTool::Exif::ExifTime($val)',
              value_conv_inv: 'Image::ExifTool::IPTC::IptcTime($val)',
              print_conv_inv: 'Image::ExifTool::IPTC::InverseDateOrTime($val)',
          },
          0x41 => {
              name: 'OriginatingProgram',
              type: 'string',
              size: (0..32),
          },
          0x46 => {
              name: 'ProgramVersion',
              type: 'string',
              size: (0..10),
          },
          0x4b => {
              name: 'ObjectCycle',
              type: 'string',
              size: 1,
              print_conv: {
                  'a' => 'Morning',
                  'p' => 'Evening',
                  'b' => 'Both Morning and Evening',
              },
          },
          0x50 => {
              name: 'By-line',
              list: true,
              type: 'string',
              size: (0..32),
          },
          0x55 => {
              name: 'By-lineTitle',
              list: true,
              type: 'string',
              size: (0..32),
          },
          0x5a => {
              name: 'City',
              type: 'string',
              size: (0..32),
          },
          0x5c => {
              name: 'Sub-location',
              type: 'string',
              size: (0..32),
          },
          0x5f => {
              name: 'Province-State',
              type: 'string',
              size: (0..32),
          },
          0x64 => {
              name: 'Country-PrimaryLocationCode',
              type: 'string',
              size: 3,
          },
          0x65 => {
              name: 'Country-PrimaryLocationName',
              type: 'string',
              size: (0..64),
          },
          0x67 => {
              name: 'OriginalTransmissionReference',
              type: 'string',
              size: (0..32),
          },
          0x69 => {
              name: 'Headline',
              type: 'string',
              size: (0..256),
          },
          0x6e => {
              name: 'Credit',
              type: 'string',
              size: (0..32),
          },
          0x73 => {
              name: 'Source',
              type: 'string',
              size: (0..32),
          },
          0x74 => {
              name: 'CopyrightNotice',
              type: 'string',
              size: (0..128),
          },
          0x76 => {
              name: 'Contact',
              list: true,
              type: 'string',
              size: (0..128),
          },
          0x78 => {
              name: 'Caption-Abstract',
              type: 'string',
              size: (0..2000),
          },
          0x79 => {
              name: 'LocalCaption',
              type: 'string',
              size: (0..256), # (guess)
              notes: %{
                  I haven't found a reference for the format of tags 121, 184-188 and
                  225-232, so I have just make them writable as strings with
                  reasonable length.  Beware that if this is wrong, other utilities
                  won't be able to read these tags as written by ExifTool
              },
          },
          0x7a => {
              name: 'Writer-Editor',
              list: true,
              type: 'string',
              size: (0..32),
          },
          0x7d => {
              name: 'RasterizedCaption',
              type: 'undef',
              size: 7360,
              binary: 1,
          },
          0x82 => {
              name: 'ImageType',
              type: 'string',
              size: 2,
          },
          0x83 => {
              name: 'ImageOrientation',
              type: 'string',
              size: 1,
              print_conv: {
                  'P' => 'Portrait',
                  'L' => 'Landscape',
                  'S' => 'Square',
              },
          },
          0x87 => {
              name: 'LanguageIdentifier',
              type: 'string',
              size: (2..3),
          },
          0x96 => {
              name: 'AudioType',
              type: 'string',
              size: 2,
              print_conv: {
                  '1A' => 'Mono Actuality',
                  '2A' => 'Stereo Actuality',
                  '1C' => 'Mono Question and Answer Session',
                  '2C' => 'Stereo Question and Answer Session',
                  '1M' => 'Mono Music',
                  '2M' => 'Stereo Music',
                  '1Q' => 'Mono Response to a Question',
                  '2Q' => 'Stereo Response to a Question',
                  '1R' => 'Mono Raw Sound',
                  '2R' => 'Stereo Raw Sound',
                  '1S' => 'Mono Scener',
                  '2S' => 'Stereo Scener',
                  '0T' => 'Text Only',
                  '1V' => 'Mono Voicer',
                  '2V' => 'Stereo Voicer',
                  '1W' => 'Mono Wrap',
                  '2W' => 'Stereo Wrap',
              },
          },
          0x97 => {
              name: 'AudioSamplingRate',
              type: 'digits',
              size: 6,
          },
          0x98 => {
              name: 'AudioSamplingResolution',
              type: 'digits',
              size: 2,
          },
          0x99 => {
              name: 'AudioDuration',
              type: 'digits',
              size: 6,
          },
          0x9a => {
              name: 'AudioOutcue',
              type: 'string',
              size: (0..64),
          },
          0xb8 => {
              name: 'JobID',
              type: 'string',
              size: (0..64), # (guess)
          },
          0xb9 => {
              name: 'MasterDocumentID',
              type: 'string',
              size: (0..256), # (guess)
          },
          0xba => {
              name: 'ShortDocumentID',
              type: 'string',
              size: (0..64), # (guess)
          },
          0xbb => {
              name: 'UniqueDocumentID',
              type: 'string',
              size: (0..128), # (guess)
          },
          0xbc => {
              name: 'OwnerID',
              type: 'string',
              size: (0..128), # (guess)
          },
          0xc8 => {
              name: 'ObjectPreviewFileFormat',
              type: 'int16u',
              print_conv: "fileFormat",
          },
          0xc9 => {
              name: 'ObjectPreviewFileVersion',
              type: 'int16u',
          },
          0xca => {
              name: 'ObjectPreviewData',
              type: 'undef',
              size: (0..256000),
              binary: 1,
          },
          0xdd => {
              name: 'Prefs',
              type: 'string',
              size: (0..64),
              notes: 'PhotoMechanic preferences',
              print_conv: %{
                  $val =~ s[\s*(\d+):\s*(\d+):\s*(\d+):\s*(\S*)]
                           [Tagged:$1, ColorClass:$2, Rating:$3, FrameNum:$4];
                  return $val;
              },
              print_conv_inv: %{
                  $val =~ s[Tagged:\s*(\d+).*ColorClass:\s*(\d+).*Rating:\s*(\d+).*FrameNum:\s*(\S*)]
                           [$1:$2:$3:$4]is;
                  return $val;
              },
          },
          0xe1 => {
              name: 'ClassifyState',
              type: 'string',
              size: (0..64), # (guess)
          },
          0xe4 => {
              name: 'SimilarityIndex',
              type: 'string',
              size: (0..32), # (guess)
          },
          0xe6 => {
              name: 'DocumentNotes',
              type: 'string',
              size: (0..1024), # (guess)
          },
          0xe7 => {
              name: 'DocumentHistory',
              type: 'string',
              size: (0..256), # (guess)
          },
          0xe8 => {
              name: 'ExifCameraInfo',
              type: 'string',
              size: (0..4096), # (guess)
          },
          0xff => { #PH
              name: 'CatalogSets',
              list: 1,
              type: 'string',
              size: (0..256), # (guess)
              notes: 'written by iView MediaPro',
          },
        },
      },
      0x03 => {
        name: 'IPTCNewsPhoto',
        datasets: {
          0x00 => {
              name: 'NewsPhotoVersion',
              type: 'int16u',
              mandatory: 1,
          },
          0x0a => {
              name: 'IPTCPictureNumber',
              type: 'string',
              size: 16,
              notes: '4 numbers: 1-Manufacturer ID, 2-Equipment ID, 3-Date, 4-Sequence',
              print_conv: 'Image::ExifTool::IPTC::ConvertPictureNumber($val)',
              print_conv_inv: 'Image::ExifTool::IPTC::InvConvertPictureNumber($val)',
          },
          0x14 => {
              name: 'IPTCImageWidth',
              type: 'int16u',
          },
          0x1e => {
              name: 'IPTCImageHeight',
              type: 'int16u',
          },
          0x28 => {
              name: 'IPTCPixelWidth',
              type: 'int16u',
          },
          0x32 => {
              name: 'IPTCPixelHeight',
              type: 'int16u',
          },
          0x37 => {
              name: 'SupplementalType',
              type: 'int8u',
              print_conv: {
                  0x00 => 'Main Image',
                  0x01 => 'Reduced Resolution Image',
                  0x02 => 'Logo',
                  0x03 => 'Rasterized Caption',
              },
          },
          0x3c => {
              name: 'ColorRepresentation',
              type: 'int16u',
              print_hex: 1,
              print_conv: {
                  0x000 => 'No Image, Single Frame',
                  0x100 => 'Monochrome, Single Frame',
                  0x300 => '3 Components, Single Frame',
                  0x301 => '3 Components, Frame Sequential in Multiple Objects',
                  0x302 => '3 Components, Frame Sequential in One Object',
                  0x303 => '3 Components, Line Sequential',
                  0x304 => '3 Components, Pixel Sequential',
                  0x305 => '3 Components, Special Interleaving',
                  0x400 => '4 Components, Single Frame',
                  0x401 => '4 Components, Frame Sequential in Multiple Objects',
                  0x402 => '4 Components, Frame Sequential in One Object',
                  0x403 => '4 Components, Line Sequential',
                  0x404 => '4 Components, Pixel Sequential',
                  0x405 => '4 Components, Special Interleaving',
              },
          },
          0x40 => {
              name: 'InterchangeColorSpace',
              type: 'int8u',
              print_conv: {
                  0x01 => 'X,Y,Z CIE',
                  0x02 => 'RGB SMPTE',
                  0x03 => 'Y,U,V (K) (D65)',
                  0x04 => 'RGB Device Dependent',
                  0x05 => 'CMY (K) Device Dependent',
                  0x06 => 'Lab (K) CIE',
                  0x07 => 'YCbCr',
                  0x08 => 'sRGB',
              },
          },
          0x41 => {
              name: 'ColorSequence',
              type: 'int8u',
          },
          0x42 => {
              name: 'ICC_Profile',
              binary: 1,
          },
          0x46 => {
              name: 'ColorCalibrationMatrix',
              binary: 1,
          },
          0x50 => {
              name: 'LookupTable',
              binary: 1,
          },
          0x54 => {
              name: 'NumIndexEntries',
              type: 'int16u',
          },
          0x55 => {
              name: 'ColorPalette',
              binary: 1,
          },
          0x56 => {
              name: 'IPTCBitsPerSample',
              type: 'int8u',
          },
          0x5a => {
              name: 'SampleStructure',
              type: 'int8u',
              print_conv: {
                  0x00 => 'OrthogonalConstangSampling',
                  0x01 => 'Orthogonal4-2-2Sampling',
                  0x02 => 'CompressionDependent',
              },
          },
          0x64 => {
              name: 'ScanningDirection',
              type: 'int8u',
              print_conv: {
                  0x00 => 'L-R, Top-Bottom',
                  0x01 => 'R-L, Top-Bottom',
                  0x02 => 'L-R, Bottom-Top',
                  0x03 => 'R-L, Bottom-Top',
                  0x04 => 'Top-Bottom, L-R',
                  0x05 => 'Bottom-Top, L-R',
                  0x06 => 'Top-Bottom, R-L',
                  0x07 => 'Bottom-Top, R-L',
              },
          },
          0x66 => {
              name: 'IPTCImageRotation',
              type: 'int8u',
              print_conv: {
                  0x00 => 0,
                  0x01 => 90,
                  0x02 => 180,
                  0x03 => 270,
              },
          },
          0x6e => {
              name: 'DataCompressionMethod',
              type: 'int32u',
          },
          0x78 => {
              name: 'QuantizationMethod',
              type: 'int8u',
              print_conv: {
                  0x00 => 'Linear Reflectance/Transmittance',
                  0x01 => 'Linear Density',
                  0x02 => 'IPTC Ref B',
                  0x03 => 'Linear Dot Percent',
                  0x04 => 'AP Domestic Analogue',
                  0x05 => 'Compression Method Specific',
                  0x06 => 'Color Space Specific',
                  0x07 => 'Gamma Compensated',
              },
          },
          0x7d => {
              name: 'EndPoints',
              binary: 1,
          },
          0x82 => {
              name: 'ExcursionTolerance',
              type: 'int8u',
              print_conv: {
                  0x00 => 'Not Allowed',
                  0x01 => 'Allowed',
              },
          },
          0x87 => {
              name: 'BitsPerComponent',
              type: 'int8u',
          },
          0x8c => {
              name: 'MaximumDensityRange',
              type: 'int16u',
          },
          0x91 => {
              name: 'GammaCompensatedValue',
              type: 'int16u',
          },
        },
      },
      0x07 => {
        # Record 7 -- Pre-object Data
        name: 'IPTCPreObjectData',
        datasets: {
          0x0a => {
              name: 'SizeMode',
              type: 'int8u',
              print_conv: {
                  0x00 => 'Size Not Known',
                  0x01 => 'Size Known',
              },
          },
          0x14 => {
              name: 'MaxSubfileSize',
              type: 'int32u',
          },
          0x5a => {
              name: 'ObjectSizeAnnounced',
              type: 'int32u',
          },
          0x5f => {
              name: 'MaximumObjectSize',
              type: 'int32u',
          },
        },
      },
      0x08 => {
        # Record 8 -- ObjectData
        name: 'IPTCObjectData',
        datasets: {
          0x0a => {
            name: 'SubFile',
            list: true,
            binary: 1,
          },
        },
      },
      0x09 => {
        # Record 9 -- PostObjectData
        name: 'IPTCPostObjectData',
        datasets: {
          0x0a => {
            name: 'ConfirmedObjectSize',
            type: 'int32u',
          },
        },
      },
      0xf0 => {
        # Record 240 -- FotoStation proprietary data (ref PH)
        name: 'IPTCFotoStation',
      },
    }

    def initialize(io, length:)
      @fields = []
      read_fields(io, length: length)
    end

    def encoding
      @encoding || DEFAULT_ENCODING
    end

    def [](name)
      field_values[name]
    end

    def to_hash
      field_values
    end

    private

    def read_fields(io, length:)
      start = io.tell
      finish = start + length

      until io.eof? || io.tell >= finish
        read_field(io)
      end
    end

    MARKER = 0x1c

    def read_field(io)
      marker = io.getbyte
      unless marker == MARKER
        raise MalformedIPTC, "Expected marker byte, got: #{marker}"
      end

      record_number = io.getbyte

      dataset_number = io.getbyte

      # Length can be a variable integer
      length = io.read(2).unpack("S>").first
      if length & 0x8000 == 0x8000
        size = length & 0x7fff
        length = 0
        size.times do
          length = (length << 8) + io.readbyte
        end
      end

      start = io.tell
      finish = start + length

      field = Field.new(record_number: record_number, dataset_number: dataset_number, data: io.read(length), encoding: encoding)
      @fields << field

      # IPTC specifies that records must be ordered. This dataset is in the
      # first possible record, so later records (like the main application
      # record) should all receive this encoding.
      #
      # There is a list of encodings here:
      # https://en.wikipedia.org/wiki/ISO/IEC_2022#ISO.2FIEC_2022_character_sets
      #
      # Ruby doesn't support a bunch of them, so we really only support UTF-8
      # and fall back to ASCII.
      if field.dataset? and field.dataset_name == "CodedCharacterSet"
        case field.value
        when "\x1b%G"
          @encoding = Encoding::UTF_8
        else
          EXIFR.logger.warn { "IPTC: Unknown codec character set: #{field.value.inspect}" }
        end
      end

      unless io.tell == finish
        io.seek(finish)
      end
    end

    def field_values
      @field_values ||= @fields.each_with_object({}) do |field, index|
        if field.dataset?
          if field.dataset[:list]
            (index[field.dataset_name] ||= []) << field.value
          else
            index[field.dataset_name] = field.value
          end
        end
      end
    end

    class Field
      def initialize(record_number:, dataset_number:, data:, encoding:)
        @record_number = record_number
        @dataset_number = dataset_number
        @data = data
        @encoding = encoding
      end

      attr_reader :record_number

      def record?
        RECORDS.has_key? record_number
      end

      def record
        RECORDS[record_number]
      end

      def record_name
        if record?
          record[:name]
        end
      end

      attr_reader :dataset_number, :data

      def dataset?
        if record?
          record[:datasets] && record[:datasets].has_key?(dataset_number)
        end
      end

      def dataset
        if dataset?
          record[:datasets][dataset_number]
        end
      end

      def dataset_name
        if dataset?
          dataset[:name]
        end
      end

      def dataset_type
        if dataset?
          dataset[:type]
        end
      end

      attr_reader :data

      attr_reader :encoding

      def value
        case dataset_type
        when "string"
          # Record number 1 is always the default encoding
          if record_number == 1
            @data.force_encoding(DEFAULT_ENCODING)
          # Records 2-6 and 8 respect tagged encoding
          elsif (2..6).include?(record_number) || record_number == 8
            @data.force_encoding(encoding)
          # Other behaviour is undefined
          else
            @data
          end
        when "digits"
          @data
        when "int8u"
          @data.unpack("C").first
        when "int16u"
          @data.unpack("S").first
        when "int32u"
          @data.unpack("L").first
        else
          @data
        end
      end

      def inspect
        "#<%s:0x%014x record=%s dataset=%s %p>" % [self.class, object_id, inspect_record, inspect_dataset, value]
      end

      private def inspect_record
        if record?
          record_name
        else
          "unknown:0x%x" % [record_number]
        end
      end

      private def inspect_dataset
        if dataset?
          dataset_name
        else
          "unknown:0x%x" % [dataset_number]
        end
      end
    end
  end
end
