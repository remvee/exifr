task :default => :test


require 'rake/testtask'

Rake::TestTask.new do |t|
  t.libs << 'lib' << 'tests'
  t.test_files = FileList['tests/test*.rb']
end


require 'rcov/rcovtask'

Rcov::RcovTask.new do |t|
  t.libs << 'lib' << 'tests'
  t.test_files = FileList['tests/test*.rb']
end


require 'rake/gempackagetask'

spec = Gem::Specification.new do |s|
  s.name = 'exifr'
  s.version = '0.9.1.1'
  s.author = "R.W. van 't Veer"
  s.email = 'remco@remvee.net'
  s.homepage = 'http://exifr.rubyforge.org/'
  s.summary = 'EXIF Reader is a module to read EXIF from JPEG images.'
  
  s.autorequire = 'exifr'
  s.files = FileList['{bin,lib,test}/**/*'].exclude('rdoc').to_a
  
  s.has_rdoc = true
  s.extra_rdoc_files = ['README', 'CHANGELOG']
  
  s.bindir = 'bin'
  s.executables = ['exifr']
end

Rake::GemPackageTask.new(spec) do |pkg|
  pkg.need_tar = true
end
