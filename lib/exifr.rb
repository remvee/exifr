# Copyright (c) 2006, 2007, 2008, 2009, 2010, 2011 - R.W. van 't Veer

module EXIFR
  class MalformedImage < StandardError; end
  class MalformedJPEG < MalformedImage; end
  class MalformedTIFF < MalformedImage; end
end

require 'exifr/jpeg'
require 'exifr/tiff'
