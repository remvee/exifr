require 'nokogiri'

module EXIFR
  class XMP
    NAMESPACES = {
      'dc' => "http://purl.org/dc/elements/1.1/",
    }

    class Namespace
      def initialize(xmp, namespace)
        @xmp = xmp
        @namespace = namespace
      end

      def inspect
        "\#<EXIFR::XMP::Namespace:#{@namespace}>"
      end

      def method_missing(method, *args)
        embedded_attribute(method) || standalone_attribute(method)
      end

      private

      def embedded_attribute(name)
        description = xml.xpath('//rdf:Description').first
        attribute = description.attribute("#{name}")
        attribute ? attribute.text : nil
      end

      def standalone_attribute(name)
        attribute_xpath = "//#{@namespace}:#{name}"
        attribute = xml.xpath(attribute_xpath).first
        return unless attribute

        array_value = attribute.xpath("./rdf:Bag | ./rdf:Seq | ./rdf:Alt").first
        if array_value
          items = array_value.xpath("./rdf:li")
          items.map { |i| i.text }
        else
          raise "Don't know how to handle: \n" + attribute.to_s
        end
      end

      def xml
        @xmp.xml
      end
    end

    attr_reader :xml

    def initialize(xml)
      doc = Nokogiri::XML(xml)
      @xml = doc.root
      @namespaces = doc.collect_namespaces

      # add all namespaces
      @namespaces.each do |ns, url|
        @xml.add_namespace_definition ns, url
      end
    end

    def method_missing(namespace, *args)
      if has_namespace?(namespace)
        Namespace.new(self, namespace)
      else
        super
      end
    end

    def respond_to?(method)
      has_namespace?(method) or super
    end

    private

    def has_namespace?(namespace)
      @namespaces.has_key?("xmlns:#{namespace}")
    end
  end
end
