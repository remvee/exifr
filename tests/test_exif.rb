#!/usr/bin/env ruby

require 'test_helper'

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
end