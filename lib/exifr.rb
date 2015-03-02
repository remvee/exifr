# Copyright (c) 2006-2015 - R.W. van 't Veer

require 'logger'

module EXIFR
  class MalformedImage < StandardError; end
  class MalformedJPEG < MalformedImage; end
  class MalformedTIFF < MalformedImage; end

  class << self; attr_accessor :logger; end
  self.logger = Logger.new(STDERR)
end

require 'exifr/jpeg'
require 'exifr/tiff'
