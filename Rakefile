# Copyright (c) 2006, 2007, 2008, 2009, 2010, 2011 - R.W. van 't Veer

require 'rake/rdoctask'
require 'rake/testtask'

task :default => :test

desc 'Generate site'
task :site => :rdoc do
  system 'rsync -av --delete doc/ remvee@rubyforge.org:/var/www/gforge-projects/exifr'
end

Rake::RDocTask.new do |rd|
  rd.title = 'EXIF Reader for Ruby API Documentation'
  rd.main = "README.rdoc"
  rd.rdoc_dir = "doc/api"
  rd.rdoc_files.include("README.rdoc", "lib/**/*.rb")
end


Rake::TestTask.new do |t|
  t.libs << 'lib' << 'tests'
  t.test_files = FileList['tests/*_test.rb']
end

begin
  require 'rcov/rcovtask'

  Rcov::RcovTask.new do |t|
    t.libs << 'lib' << 'tests'
    t.test_files = FileList['tests/*_test.rb']
  end

  desc 'Remove all artifacts left by testing and packaging'
  task :clean => [:clobber_rdoc, :clobber_rcov]
rescue LoadError
  desc 'Remove all artifacts left by testing and packaging'
  task :clean => [:clobber_rdoc]
end
