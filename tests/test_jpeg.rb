#!/usr/bin/env ruby

require 'test_helper'
require 'stringio'

class TestJPEG < Test::Unit::TestCase
  def test_initialize
    all_test_images.each do |fname|
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
  
  def test_comment
    assert_equal JPEG.new(f('image.jpg')).comment, "Here's a comment!"
  end
  
  def test_exif
    assert ! JPEG.new(f('image.jpg')).exif?
    assert JPEG.new(f('exif.jpg')).exif?
  end
  
  def test_multiple_app1
    assert JPEG.new(f('multiple-app1.jpg')).exif?
  end
  
  def test_patch_through
    jpeg = JPEG.new(f('exif.jpg'))
    jpeg.exif.each do |k,v|
      assert_equal v, jpeg.send(k) 
    end
  end
end