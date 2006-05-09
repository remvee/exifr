#!/usr/bin/env ruby

require 'test_helper'
require 'stringio'

class TestJPEG < Test::Unit::TestCase
  def test_initialize
    all_test_data.each do |fname|
      assert_nothing_raised do
        JPEG.new(fname)
      end
      assert_nothing_raised do
        open(fname) { |rd| JPEG.new(rd) }
      end
      assert_nothing_raised do
        open(fname) { |rd| JPEG.new(StringIO.new(rd.read)) }
      end
    end
  end
  
  def test_size
    j = JPEG.new(f('image.jpg'))
    assert_equal j.width, 2272
    assert_equal j.height, 1704

    j = JPEG.new(f('exif.jpg'))
    assert_equal j.width, 2272
    assert_equal j.height, 1704

    j = JPEG.new(f('1x1.jpg'))
    assert_equal j.width, 1
    assert_equal j.height, 1
  end
end