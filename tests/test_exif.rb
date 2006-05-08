#!/usr/bin/env ruby

require 'test_helper'

class TestEXIF < Test::Unit::TestCase
  def test_initialize
    [['canon-g3.exif', 'Canon PowerShot G3']].each do |fname,model|
      data = open(f(fname)) { |rd| rd.read }
      assert_equal EXIF.new(data).model, model
    end
  end
end