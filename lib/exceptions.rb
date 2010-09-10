module EXIFR
  class MalformedImage < StandardError; end
  class MalformedJPEG < MalformedImage; end
  class MalformedTIFF < MalformedImage; end
end
