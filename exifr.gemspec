spec = Gem::Specification.new do |s|
  s.name = 'exifr'
  s.version = '0.10.6'
  s.author = "R.W. van 't Veer"
  s.email = 'remco@remvee.net'
  s.homepage = 'http://exifr.rubyforge.org/'
  s.summary = 'EXIF Reader is a module to read EXIF from JPEG images.'
  
  s.autorequire = 'exifr'
  s.files = %w(Rakefile) + Dir['{bin,lib,tests}/**/*']
  
  s.has_rdoc = true
  s.extra_rdoc_files = %w(README.rdoc CHANGELOG)
  
  s.bindir = 'bin'
  s.executables = ['exifr']
end
