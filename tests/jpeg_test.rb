#!/usr/bin/env ruby
#
# Copyright (c) 2006-2015 - R.W. van 't Veer

require 'test_helper'

class JPEGTest < TestCase
  def test_initialize
    all_test_jpegs.each do |fname|
      assert JPEG.open(fname)
      open(fname, "rb") { |io| assert JPEG.new(io) }
      assert JPEG.new(StringIO.new(File.read(fname)))
    end
  end

  def test_raises_malformed_jpeg
    begin
      JPEG.new(StringIO.new("djibberish"))
    rescue MalformedJPEG => ex
      assert ex
    end
  end

  def test_size
    j = JPEG.open(f('image.jpg'))
    assert_equal j.width, 100
    assert_equal j.height, 75

    j = JPEG.open(f('exif.jpg'))
    assert_equal j.width, 100
    assert_equal j.height, 75

    j = JPEG.open(f('1x1.jpg'))
    assert_equal j.width, 1
    assert_equal j.height, 1
  end

  def test_comment
    assert_equal JPEG.open(f('image.jpg')).comment, "Here's a comment!"
  end

  def test_exif
    assert ! JPEG.open(f('image.jpg')).exif?
    assert JPEG.open(f('exif.jpg')).exif?
    assert JPEG.open(f('exif.jpg')).exif.date_time
    assert JPEG.open(f('exif.jpg')).exif.f_number
  end

  def test_multiple_app1
    assert JPEG.open(f('multiple-app1.jpg')).exif?
  end

  def test_thumbnail
    count = 0
    all_test_jpegs.each do |fname|
      jpeg = JPEG.open(fname)
      unless jpeg.thumbnail.nil?
        assert JPEG.new(StringIO.new(jpeg.thumbnail))
        count += 1
      end
    end

    assert count > 0, 'no thumbnails found'
  end

  def test_iptc
    jpeg = JPEG.open(f('iptc.jpg'))

    assert jpeg.iptc?
    assert_equal "Kingston", jpeg.iptc["City"]
  end

  def test_xmp
    jpeg = JPEG.open(f('xmp.jpg'))

    assert jpeg.xmp?
    assert_equal ["Copyright 2004 Phil Harvey"], jpeg.xmp.dc.rights
    assert_equal ["Test IPTC picture"], jpeg.xmp.dc.title
  end
end
