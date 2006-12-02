require 'rake/rdoctask'
require 'rake/gempackagetask'
require 'rake/testtask'
require 'rcov/rcovtask'

task :default => :test

spec = Gem::Specification.new do |s|
  s.name = 'exifr'
  s.version = '0.9.4'
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

Rake::RDocTask.new do |rd|
  rd.title = 'EXIF Reader for Ruby API Documentation'
  rd.main = "README"
  rd.rdoc_dir = "doc/api"
  rd.rdoc_files.include("README", "lib/**/*.rb")
end


Rake::TestTask.new do |t|
  t.libs << 'lib' << 'tests'
  t.test_files = FileList['tests/test*.rb']
end

Rcov::RcovTask.new do |t|
  t.libs << 'lib' << 'tests'
  t.test_files = FileList['tests/test*.rb']
end

desc 'Remove all artifacts left by testing and packaging'
task :clean => [:clobber_package, :clobber_rdoc, :clobber_rcov]
