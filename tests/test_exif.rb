#!/usr/bin/env ruby

require File.join(File.dirname(__FILE__), 'test_helper')

class TestEXIF < Test::Unit::TestCase
  def test_initialize
    [['canon-g3.exif', 'Canon PowerShot G3']].each do |fname,model|
      data = open(f(fname)) { |rd| rd.read }
      assert_equal EXIF.new(data).model, model
    end
    
    assert_raise RuntimeError, 'no II or MM marker found' do
      EXIF.new('X' * 100)
    end
  end
  
  def test_dates
    all_test_exifs.each do |fname|
      data = open(fname) { |rd| rd.read }
      assert_kind_of Time, EXIF.new(data).date_time
    end
  end
  
  def test_orientation
    all_test_exifs.each do |fname|
      data = open(fname) { |rd| rd.read }
      orientation = EXIF.new(data).orientation
      assert_kind_of Module, orientation
      assert orientation.respond_to?(:to_i)
      assert orientation.respond_to?(:transform_rmagick)
    end
  end
  
  def test_thumbnail
    assert_not_nil JPEG.new(f('exif.jpg')).exif.thumbnail
    
    all_test_exifs.each do |fname|
      data = open(fname) { |rd| rd.read }
      thumbnail = EXIF.new(data).thumbnail
      assert_nothing_raised do
        JPEG.new(StringIO.new(thumbnail))
      end
    end
  end
  
  def test_exif_offset
    assert JPEG.new(f('exif.jpg')).exif.include?(:exif_version)
  end
  
  def test_gps
    data = open(f('gps.exif')){|rd|rd.read}
    exif = EXIF.new(data)
    assert exif.include?(:gps_version_id)
    assert_equal "\2\2\0\0", exif.gps_version_id
    assert_equal 'N', exif.gps_latitude_ref
    assert_equal 'W', exif.gps_longitude_ref
    assert_equal [5355537.quo(100000), 0.quo(1), 0.quo(1)], exif.gps_latitude
    assert_equal [678886.quo(100000), 0.quo(1), 0.quo(1)], exif.gps_longitude
    assert_equal 'WGS84', exif.gps_map_datum
    
    (all_test_exifs - [f('gps.exif')]).each do |fname|
      data = open(fname) { |rd| rd.read }
      assert EXIF.new(data).keys.map{|k|k.to_s}.grep(/gps/).empty?
    end
  end
end