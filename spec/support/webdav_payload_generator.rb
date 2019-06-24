module WebDavPayloadGenerator
  WEBDAV_NAMESPACE_HREF = "DAV:"
  WEBDAV_NAMESPACE_PREFIX = "D"

  def render(root_type)
    raise ArgumentError.new 'Expecting block' unless block_given?
    doc = Nokogiri::XML::Builder.new do |xml|
      xml.send(root_type.to_s, "xmlns:#{WEBDAV_NAMESPACE_PREFIX}" => WEBDAV_NAMESPACE_HREF) do
        xml.parent.namespace = xml.parent.add_namespace_definition(WEBDAV_NAMESPACE_PREFIX, WEBDAV_NAMESPACE_HREF)
        yield xml[WEBDAV_NAMESPACE_PREFIX]
      end
    end
    doc.to_xml
  end

  def propfind_xml(*props)
    render(:propfind) do |xml|
      xml.prop do
        props.each do |prop|
          xml.send(prop.to_sym)
        end
      end
    end
  end
end

RSpec.configure do |c|
  c.include WebDavPayloadGenerator
end
