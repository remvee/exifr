#!/usr/bin/env ruby

require 'test/unit'
require 'stringio'
require 'pp'

$:.unshift("#{File.dirname(__FILE__)}/../lib")
require 'exifr'
include EXIFR


def all_test_images
  Dir[f('*.jpg')]
end

def all_test_exifs
  Dir[f('*.exif')]
end

def f(fname)
  "#{File.dirname(__FILE__)}/data/#{fname}"
end
