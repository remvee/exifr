spec = Gem::Specification.new do |s|
  s.name = 'exifr'
  s.version = '1.3.7-SNAPSHOT'
  s.author = "R.W. van 't Veer"
  s.email = 'exifr@remworks.net'
  s.homepage = 'http://github.com/remvee/exifr/'
  s.summary = 'Read EXIF from JPEG and TIFF images'
  s.description = 'EXIF Reader is a module to read EXIF from JPEG and TIFF images.'
  s.licenses = ['MIT']
  s.required_ruby_version = '>= 1.8.7'

  s.files = %w(Rakefile Gemfile bin/exifr)
  s.files += %w(lib/exifr.rb lib/exifr/jpeg.rb lib/exifr/tiff.rb)
  s.files += %w(tests/data/1x1.jpg tests/data/Canon_PowerShot_A85.exif tests/data/Casio-EX-S20.exif tests/data/FUJIFILM-FinePix_S3000.exif tests/data/Panasonic-DMC-LC33.exif tests/data/Trust-DC3500_MINI.exif tests/data/apple-aperture-1.5.exif tests/data/bad-shutter_speed_value.exif tests/data/canon-g3.exif tests/data/endless-loop.exif tests/data/exif.jpg tests/data/gopro_hd2.exif tests/data/gps-altitude.jpg tests/data/gps.exif tests/data/image.jpg tests/data/multiple-app1.jpg tests/data/negative-exposure-bias-value.exif tests/data/nikon_d1x.tif tests/data/out-of-range.exif tests/data/plain.tif tests/data/samsung-sc-02b.jpg tests/data/sony-a7ii.exif tests/data/user-comment.exif tests/data/weird_date.exif tests/jpeg_test.rb tests/test_helper.rb tests/tiff_test.rb)

  s.executables = %w(exifr)

  if s.respond_to?(:add_development_dependency)
    s.add_development_dependency 'test-unit', '3.1.5'
    s.add_development_dependency 'rake', '~> 12'
  end

  if s.respond_to?(:metadata)
    s.metadata = {
      'bug_tracker_uri' => 'https://github.com/remvee/exifr/issues',
      'changelog_uri' => 'https://github.com/remvee/exifr/blob/master/CHANGELOG',
      'documentation_uri' => 'https://remvee.github.io/exifr/api/',
      'homepage_uri'      => 'https://remvee.github.io/exifr/',
      'source_code_uri' => 'https://github.com/remvee/exifr'
    }
  end
end
