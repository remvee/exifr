# Copyright (c) 2006 - R.W. van 't Veer

module EXIFR
  class TiffHeader # :nodoc:
    attr_reader :data, :fields

    def initialize(data, offset = nil)
      @data = data
      @fields = []

      class << @data
        attr_accessor :short, :long
        def readshort(pos); self[pos..(pos + 1)].unpack(@short)[0]; end
        def readlong(pos); self[pos..(pos + 3)].unpack(@long)[0]; end
      end

      case @data[0..1]
      when 'II'; @data.short, @data.long = 'v', 'V'
      when 'MM'; @data.short, @data.long = 'n', 'N'
      else; raise 'no II or MM marker found'
      end

      readIfds(offset || @data.readlong(4))
    end

    def readIfds(pos)
      while pos != 0 do
        num = @data.readshort(pos)
        pos += 2

        num.times do
          fields << TiffField.new(@data, pos)
          pos += 12
        end

        pos = @data.readlong(pos)
      end
    end
  end

  class TiffField # :nodoc:
    attr_reader :tag, :offset, :value

    def initialize(data, pos)
      @tag, count, @offset = data.readshort(pos), data.readlong(pos + 4), data.readlong(pos + 8)

      case data.readshort(pos + 2)
      when 1, 6 # byte, signed byte
        # TODO handle signed bytes
        len, pack = count, proc { |d| d }
      when 2 # ascii
        len, pack = count, proc { |d| d.sub(/\000.*$/, '').strip }
      when 3, 8 # short, signed short
        # TODO handle signed
        len, pack = count * 2, proc { |d| d.unpack(data.short + '*') }
      when 4, 9 # long, signed long
        # TODO handle signed
        len, pack = count * 4, proc { |d| d.unpack(data.long + '*') }
      when 5, 10
        len, pack = count * 8, proc do |d|
          r = []
          d.unpack(data.long + '*').each_with_index do |v,i|
            i % 2 == 0 ? r << [v] : r.last << v
          end
          r.map do |f|
            if f[1] == 0 # allow NaN and Infinity
              f[0].to_f.quo(f[1])
            else
              Rational.reduce(*f)
            end
          end
        end
      end

      if len && pack
        start = len > 4 ? @offset : (pos + 8)
        @value = pack[data[start..(start + len)]]
      end
    end
  end
end
