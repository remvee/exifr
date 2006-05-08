#!/usr/bin/env ruby

require 'pp'
require 'test/unit'

$:.unshift("#{File.dirname(__FILE__)}/../lib")
require 'exifr'
include EXIFR


def all_test_data
  Dir[f('*.jpg')]
end

def f(fname)
  "#{File.dirname(__FILE__)}/data/#{fname}"
end
