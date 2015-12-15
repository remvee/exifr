#!/usr/bin/env ruby

require 'test_helper'

class IPTCTest < TestCase
  def test_iptc_unknown_record
    iptc = EXIFR::IPTC.new(StringIO.new("\x1c\x00\x00\x05\x00Hello".b), length: 6)
    assert_equal(1, iptc.fields.size)
    refute iptc.fields.first.record?
    refute iptc.fields.first.dataset?
    assert_equal "Hello".b, iptc.fields.first.value
  end

  def test_iptc_unknown_dataset
    iptc = EXIFR::IPTC.new(StringIO.new("\x1c\x01\x01\x05\x00Hello".b), length: 6)
    assert_equal(1, iptc.fields.size)
    assert iptc.fields.first.record?
    refute iptc.fields.first.dataset?
    assert_equal "Hello".b, iptc.fields.first.value
  end

  def test_iptc_int8u
    iptc = EXIFR::IPTC.new(StringIO.new("\x1c\x03\x37\x00\x02\x01".b), length: 5)
    assert_equal({"SupplementalType" => 1}, iptc.to_hash)
  end

  def test_iptc_int16u
    iptc = EXIFR::IPTC.new(StringIO.new("\x1c\x01\x00\x00\x02\x01\x02".b), length: 6)
    assert_equal({"EnvelopeRecordVersion" => 513}, iptc.to_hash)
  end

  def test_iptc_int32u
    iptc = EXIFR::IPTC.new(StringIO.new("\x1c\x03\x6e\x00\x04\x01\x02\x04\x08".b), length: 6)
    assert_equal({"DataCompressionMethod" => 134480385}, iptc.to_hash)
  end

  def test_iptc_string
    iptc = EXIFR::IPTC.new(StringIO.new("\x1c\x01\x1e\x05\x00Hello".b), length: 6)
    assert_equal({"ServiceIdentifier" => "Hello".b}, iptc.to_hash)
  end

  def test_iptc_encoded_string
    iptc = EXIFR::IPTC.new(StringIO.new("\x1c\x01\x5a\x00\x03\x1b\x25\x47\x1c\x02\x05\x00\x03\xE2\x98\x83".b), length: 16)
    assert_equal(2, iptc.fields.size)
    assert_equal("\e%G".b, iptc["CodedCharacterSet"])
    assert_equal(Encoding::UTF_8, iptc["ObjectName"].encoding)
    assert_equal("☃".force_encoding("UTF-8"), iptc["ObjectName"])
  end

  def test_iptc_string_list
    iptc = EXIFR::IPTC.new(StringIO.new("\x1c\x01\x05\x00\x05Hello\x1c\x01\x05\x00\x05World".b), length: 20)
    assert_equal(2, iptc.fields.size)
    assert_equal(["Hello", "World"], iptc["Destination"])
  end
end
