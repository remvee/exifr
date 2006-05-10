#!/usr/bin/env ruby

require 'pp'
require 'test/unit'

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
