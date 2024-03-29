# EXIF Reader

![Gem Version](https://badge.fury.io/rb/exifr.svg)

EXIF Reader is a module to read metadata from JPEG and TIFF images.


## Examples

```ruby
require 'exifr/jpeg'
EXIFR::JPEG.new('IMG_6841.JPG').width               # => 2272
EXIFR::JPEG.new('IMG_6841.JPG').height              # => 1704
EXIFR::JPEG.new('IMG_6841.JPG').exif?               # => true
EXIFR::JPEG.new('IMG_6841.JPG').model               # => "Canon PowerShot G3"
EXIFR::JPEG.new('IMG_6841.JPG').date_time           # => Fri Feb 09 16:48:54 +0100 2007
EXIFR::JPEG.new('IMG_6841.JPG').exposure_time.to_s  # => "1/15"
EXIFR::JPEG.new('IMG_6841.JPG').f_number.to_f       # => 2.0
EXIFR::JPEG.new('enkhuizen.jpg').gps.latitude       # => 52.7197888888889
EXIFR::JPEG.new('enkhuizen.jpg').gps.longitude      # => 5.28397777777778

require 'exifr/tiff'
EXIFR::TIFF.new('DSC_0218.TIF').width               # => 3008
EXIFR::TIFF.new('DSC_0218.TIF')[1].width            # => 160
EXIFR::TIFF.new('DSC_0218.TIF').model               # => "NIKON D1X"
EXIFR::TIFF.new('DSC_0218.TIF').date_time           # => Tue May 23 19:15:32 +0200 2006
EXIFR::TIFF.new('DSC_0218.TIF').exposure_time.to_s  # => "1/100"
EXIFR::TIFF.new('DSC_0218.TIF').f_number.to_f       # => 5.0
```


## Logging warnings

When EXIF information is malformed, a warning is logged to STDERR with
the standard Ruby logger.  Log to some other location by supplying an
alternative implementation:

```ruby
EXIFR.logger = SyslogLogger.new
```


## Time zone support

EXIF does not support time zones so this code does not support time
zones.  All time stamps are created in the local time zone with:

```ruby
Time.local(..)
```

It is possible to change this behavior by supplying an alternative
implementation.  For those who prefer UTC:

```ruby
EXIFR::TIFF.mktime_proc = proc{|*args| Time.utc(*args)}
```

Or when the application depends on ActiveSupport for time zone handling:

```ruby
EXIFR::TIFF.mktime_proc = proc{|*args| Time.zone.local(*args)}
```


## XMP data access

If you need to access XMP data you can use the xmp gem.  More info and
examples at https://github.com/amberbit/xmp


## Development and running tests

On a fresh checkout of the repository, run `bundle install` and then
`bundle exec rake test`.


## Author

R.W. van 't Veer


## Copyright

Copyright (c) 2006-2023 - R.W. van 't Veer
