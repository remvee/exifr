#!/usr/bin/env ruby
#
# Copyright (c) 2006, 2007, 2008, 2009, 2010, 2011 - R.W. van 't Veer

require 'test_helper'

class JPEGTest < Test::Unit::TestCase
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
    assert_nothing_raised do
      JPEG.new('http://www.jpeg.org/images/blue_05.jpg')
    end
  end
  
  def test_raises_bad_url
    assert_raise BadURL do
      JPEG.new('http://google.com/nothingherexxxxxxxxxx')
    end
  end
  
  def test_raises_malformed_jpeg
    assert_raise MalformedJPEG do
      JPEG.new(StringIO.new("djibberish"))
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
    
    j = JPEG.new('http://www.jpeg.org/images/blue_05.jpg')
    assert_equal j.width, 130
    assert_equal j.height, 100
  end

  def test_comment
    assert_equal JPEG.new(f('image.jpg')).comment, "Here's a comment!"
  end

  def test_shutter_speed_value
    {
      'canon-g3.exif' => Rational(1, 1244),
      'Canon_PowerShot_A85.exif' => Rational(1, 806)
    }.each do |file, expected|
      assert_equal expected, TIFF.new(f(file)).shutter_speed_value
    end
  end

  def test_aperture_value
    {
      'canon-g3.exif' => 4.5,
      'Canon_PowerShot_A85.exif' => 2.8
    }.each do |file, expected|
      assert_equal expected, TIFF.new(f(file)).aperture_value
    end
  end

  def test_exif
    assert ! JPEG.new(f('image.jpg')).exif?
    assert JPEG.new(f('exif.jpg')).exif?
    assert_not_nil JPEG.new(f('exif.jpg')).exif.date_time
    assert_not_nil JPEG.new(f('exif.jpg')).exif.f_number
    assert_nil JPEG.new('http://www.jpeg.org/images/blue_05.jpg').exif
    assert_not_nil JPEG.new('http://www.exif.org/samples/canon-ixus.jpg').exif.date_time
  end

  def test_to_hash
    h = JPEG.new(f('image.jpg')).to_hash
    assert_equal 100, h[:width]
    assert_equal 75, h[:height]
    assert_equal "Here's a comment!", h[:comment]

    h = JPEG.new(f('exif.jpg')).to_hash
    assert_equal 100, h[:width]
    assert_equal 75, h[:height]
    assert_kind_of Time, h[:date_time]
  end

  def test_exif_dispatch
    j = JPEG.new(f('exif.jpg'))

    assert JPEG.instance_methods.include?('date_time')
    assert j.methods.include?('date_time')
    assert j.respond_to?(:date_time)
    assert j.respond_to?('date_time')
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

  def test_thumbnail
    count = 0
    all_test_jpegs.each do |fname|
      jpeg = JPEG.new(fname)
      unless jpeg.thumbnail.nil?
        assert_nothing_raised 'thumbnail not a JPEG' do
          JPEG.new(StringIO.new(jpeg.thumbnail))
        end
        count += 1
      end
    end

    assert count > 0, 'no thumbnails found'
  end

end
