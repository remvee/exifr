#!/usr/bin/env ruby
#
# Copyright (c) 2006, 2007 - R.W. van 't Veer

require File.join(File.dirname(__FILE__), 'test_helper')

class TestJPEG < Test::Unit::TestCase
  def test_initialize
    all_test_jpegs.each do |fname|
      assert_nothing_raised do
        JPEG.new(fname)
      end
      assert_nothing_raised do
        open(fname) { |rd| JPEG.new(rd) }
      end
      assert_nothing_raised do
        JPEG.new(StringIO.new(File.read(fname)))
      end
    end
  end
  
  def test_size
    j = JPEG.new(f('image.jpg'))
    assert_equal j.width, 100
    assert_equal j.height, 75

    j = JPEG.new(f('exif.jpg'))
    assert_equal j.width, 100
    assert_equal j.height, 75

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
    assert_not_nil JPEG.new(f('exif.jpg')).exif.date_time
    assert_not_nil JPEG.new(f('exif.jpg')).exif.exif.f_number
  end
  
  def test_exif_dispatch
    j = JPEG.new(f('exif.jpg'))
    assert_not_nil j.date_time
    assert_kind_of Time, j.date_time
    assert_not_nil j.f_number
    assert_kind_of Rational, j.f_number
  end
  
  def test_no_method_error
    assert_nothing_raised { JPEG.new(f('image.jpg')).f_number }
    assert_raise(NoMethodError) { JPEG.new(f('image.jpg')).foo }
  end
  
  def test_multiple_app1
    assert JPEG.new(f('multiple-app1.jpg')).exif?
  end
end