#!/usr/bin/env ruby

require 'test/unit'
require 'stringio'
require 'pp'

$:.unshift("#{File.dirname(__FILE__)}/../lib")
require 'exifr'
include EXIFR


def all_test_jpegs
  Dir[f('*.jpg')]
end


def all_test_exifs
  Dir[f('*.exif')]
end

def all_test_tiffs
  all_test_exifs + Dir[f('*.tif')]
end

def f(fname)
  "#{File.dirname(__FILE__)}/data/#{fname}"
end
