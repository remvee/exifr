#!/usr/bin/env ruby
# encoding: UTF-8

require 'test_helper'

class XMPTest < Test::Unit::TestCase
  def setup
    #@xmp = JPEG.new(f('multiple-app1.jpg'))
    @xmp = XMP.new(File.read(f('xmp.xml')))
  end

  def test_standalone_attribute_dc_title
    assert_equal ['Tytuł zdjęcia'], @xmp.dc.title
  end

  def test_standalone_attribute_dc_subject
    assert_equal ['Słowa kluczowe i numery startowe.'], @xmp.dc.subject
  end

  def test_standalone_attribute_photoshop_supplemental_categories
    assert_equal ['Nazwa imprezy'], @xmp.photoshop.SupplementalCategories
  end

  def test_embedded_attribute_Iptc4xmpCore_Location
    assert_equal 'Miejsce', @xmp.Iptc4xmpCore.Location
  end

  def test_embedded_attribute_photoshop_Category
    assert_equal 'Kategoria', @xmp.photoshop.Category
  end

  def test_not_existing_attribute
    assert_equal nil, @xmp.photoshop.abc
  end
end
