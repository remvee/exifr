# Copyright (c) 2006, 2007 - R.W. van 't Veer

require 'rake/rdoctask'
require 'rake/gempackagetask'
require 'rake/testtask'

task :default => :test

desc 'Generate site'
task :site => :rdoc do
  system 'rsync -av --delete doc/ remvee@rubyforge.org:/var/www/gforge-projects/exifr'
end

desc "Tag current trunk.  Use VERSION to provide a version spec."
task :tag do
  version = ENV['VERSION'] or raise 'provide VERSION'
  base = 'svn+ssh://remvee@rubyforge.org/var/svn/exifr'
  trunk, tag = base + "/trunk", base + "/tags/#{version}"
  system *(%w(svn copy -m) << "tagged release #{version}" << trunk << tag)
end

spec = Gem::Specification.new do |s|
  s.name = 'exifr'
  s.version = '0.10.4'
  s.author = "R.W. van 't Veer"
  s.email = 'remco@remvee.net'
  s.homepage = 'http://exifr.rubyforge.org/'
  s.summary = 'EXIF Reader is a module to read EXIF from JPEG images.'
  
  s.autorequire = 'exifr'
  s.files = FileList['Rakefile', '{bin,lib,tests}/**/*'].exclude('rdoc').to_a
  
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

begin
  require 'rcov/rcovtask'

  Rcov::RcovTask.new do |t|
    t.libs << 'lib' << 'tests'
    t.test_files = FileList['tests/test*.rb'].exclude('test_helper.rb')
  end

  desc 'Remove all artifacts left by testing and packaging'
  task :clean => [:clobber_package, :clobber_rdoc, :clobber_rcov]
rescue LoadError
  desc 'Remove all artifacts left by testing and packaging'
  task :clean => [:clobber_package, :clobber_rdoc]
end
