module MultiStatusMatchers
  def multi_status_response(pattern)
    expect(last_response).to be_multi_status
    expect(last_response_xml.xpath('//D:multistatus/D:response', last_response_xml.root.namespaces)).not_to be_empty
    last_response_xml.xpath("//D:multistatus/D:response#{pattern}", last_response_xml.root.namespaces)
  end

  def multi_status_created
    expect(last_response_xml.xpath('//D:multistatus/D:response/D:status')).not_to be_empty
    expect(last_response_xml.xpath('//D:multistatus/D:response/D:status').text).to match(/Created/)
  end

  def multi_status_ok
    expect(last_response_xml.xpath('//D:multistatus/D:response/D:status')).not_to be_empty
    expect(last_response_xml.xpath('//D:multistatus/D:response/D:status').text).to match(/OK/)
  end

  def multi_status_no_content
    expect(last_response_xml.xpath('//D:multistatus/D:response/D:status')).not_to be_empty
    expect(last_response_xml.xpath('//D:multistatus/D:response/D:status').text).to match(/No Content/)
  end

  private

  def last_response_xml
    Nokogiri.XML(last_response.body)
  end
end

RSpec.configure do |c|
  c.include MultiStatusMatchers
end
