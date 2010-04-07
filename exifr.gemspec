spec = Gem::Specification.new do |s|
  s.name = 'exifr'
  s.version = '0.10.9'
  s.author = "R.W. van 't Veer"
  s.email = 'remco@remvee.net'
  s.homepage = 'http://github.com/remvee/exifr/'
  s.summary = 'EXIF Reader is a module to read EXIF from JPEG images.'

  s.files = %w(Rakefile bin/exifr)
  s.files += %w(lib/exifr.rb lib/jpeg.rb lib/tiff.rb)
  s.files += %w(tests/data/1x1.jpg tests/data/Canon_PowerShot_A85.exif tests/data/Casio-EX-S20.exif tests/data/FUJIFILM-FinePix_S3000.exif tests/data/Panasonic-DMC-LC33.exif tests/data/Trust-DC3500_MINI.exif tests/data/apple-aperture-1.5.exif tests/data/canon-g3.exif tests/data/endless-loop.exif tests/data/exif.jpg tests/data/gps.exif tests/data/image.jpg tests/data/multiple-app1.jpg tests/data/nikon_d1x.tif tests/data/out-of-range.exif tests/data/plain.tif tests/data/user-comment.exif tests/data/weird_date.exif tests/jpeg_test.rb tests/test_helper.rb tests/tiff_test.rb)

  s.has_rdoc = true
  s.rdoc_options = ['--title', 'EXIF Reader for Ruby API Documentation', '--main', 'README.rdoc']
  s.extra_rdoc_files = %w(README.rdoc CHANGELOG)

  s.executables = %w(exifr)
end
