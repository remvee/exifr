#!/usr/bin/env ruby
#
# Copyright (c) 2006, 2007, 2008, 2009, 2010, 2011 - R.W. van 't Veer

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
  Dir[f('*.tif')] + all_test_exifs
end

def f(fname)
  "#{File.dirname(__FILE__)}/data/#{fname}"
end

def assert_literally_equal(expected, actual, *args)
  assert_equal expected.to_s_literally, actual.to_s_literally, *args
end

class Hash
  def to_s_literally
    keys.map{|k| k.to_s}.sort.map{|k| "#{k.inspect} => #{self[k].inspect}" }.join(', ')
  end
end

class Object
  def to_s_literally
    to_s
  end
end
