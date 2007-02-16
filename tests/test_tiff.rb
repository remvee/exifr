#!/usr/bin/env ruby
#
# Copyright (c) 2006, 2007 - R.W. van 't Veer

require File.join(File.dirname(__FILE__), 'test_helper')

class TestTIFF < Test::Unit::TestCase
  def setup    
    @t = TIFF.new(f('nikon_d1x.tif'))
  end
  
  def test_initialize
    all_test_tiffs.each do |fname|
      assert_nothing_raised do
        TIFF.new(fname)
      end
      assert_nothing_raised do
        open(fname) { |rd| TIFF.new(rd) }
      end
      assert_nothing_raised do
        TIFF.new(StringIO.new(File.read(fname)))
      end
    end
  end
  
  def test_multiple_images
    assert_equal 2, @t.size
  end
  
  def test_size
    assert_equal 269, @t.image_width
    assert_equal 269, @t.image_length
    assert_equal 269, @t.width
    assert_equal 269, @t.height
    assert_equal 120, @t[1].image_width
    assert_equal 160, @t[1].image_length
    assert_equal 120, @t[1].width
    assert_equal 160, @t[1].height
    
    @t = TIFF.new(f('grab.tif'))
    assert_equal 23, @t.image_width
    assert_equal 24, @t.image_length
    assert_equal 23, @t.width
    assert_equal 24, @t.height
  end
  
  def test_enumerable
    assert_equal @t[1], @t.find { |i| i.exif.nil? }
  end
  
  def test_exif
    assert_not_nil @t.exif.fnumber
  end
  
  def test_misc_fields
    assert_equal 'Canon PowerShot G3', TIFF.new(f('canon-g3.exif')).model
  end
  
  def test_dates
    (all_test_tiffs - [f('weird_date.exif'), f('grab.tif')]).each do |fname|
      assert_kind_of Time, TIFF.new(fname).date_time
    end
    assert_nil TIFF.new(f('weird_date.exif')).date_time
  end
  
  def test_orientation
    all_test_exifs.each do |fname|
      orientation = TIFF.new(fname).orientation
      assert_kind_of Module, orientation
      assert orientation.respond_to?(:to_i)
      assert orientation.respond_to?(:transform_rmagick)
    end
  end
  
  def test_gps
    t = TIFF.new(f('gps.exif'))
    assert_not_nil t.gps
    assert_equal "\2\2\0\0", t.gps.gps_version_id
    assert_equal 'N', t.gps.gps_latitude_ref
    assert_equal 'W', t.gps.gps_longitude_ref
    assert_equal [5355537.quo(100000), 0.quo(1), 0.quo(1)], t.gps.gps_latitude
    assert_equal [678886.quo(100000), 0.quo(1), 0.quo(1)], t.gps.gps_longitude
    assert_equal 'WGS84', t.gps.gps_map_datum
    
    (all_test_exifs - [f('gps.exif')]).each do |fname|
      assert_nil TIFF.new(fname).gps
    end
  end
  
  def test_ifd_dispatch
    assert_nothing_raised do
      @t.fnumber
    end
    assert_not_nil @t.fnumber
    assert_kind_of Rational, @t.fnumber
  end
end