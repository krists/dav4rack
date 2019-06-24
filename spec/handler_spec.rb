require "spec_helper"

RSpec.describe DAV4Rack::Handler do
  let(:controller) { DAV4Rack::Handler.new(root: TEST_ROOT_DIRECTORY) }

  it 'should return all options' do
    expect(options('/')).to be_ok
    %w(GET PUT POST DELETE PROPFIND PROPPATCH MKCOL COPY MOVE OPTIONS HEAD LOCK UNLOCK).each do |method|
      expect(last_response.headers['allow']).to include(method)
    end
  end
  
  it 'should return headers' do
    expect(put('/test.html', {}, input: '<html/>')).to be_created
    expect(head('/test.html')).to be_ok
    
    expect(last_response.headers['etag']).not_to be_nil
    expect(last_response.headers['content-type']).to match(/html/)
    expect(last_response.headers['last-modified']).not_to be_nil
  end
  
  it 'should not find a nonexistent resource' do
    expect(get('/not_found')).to be_not_found
  end
  
  it 'should not allow directory traversal' do
    expect(get('/../htdocs')).to be_forbidden
  end
  
  it 'should create a resource and allow its retrieval' do
    expect(put('/test', {}, input: 'body')).to be_created
    expect(get('/test')).to be_ok
    expect(last_response.body).to eq('body')
  end

  it 'should return an absolute url after a put request' do
    expect(put('/test', input: 'body')).to be_created
    expect(last_response['location']).to match(/http:\/\/example\.org(:\d+)?\/test/)
  end
  
  it 'should create and find a url with escaped characters' do
    expect(put(URI.escape('/a b'), {}, input: 'body')).to be_created
    expect(get(URI.escape('/a b'))).to be_ok
    expect(last_response.body).to eq('body')
  end
  
  it 'should delete a single resource' do
    expect(put('/test', {}, input: 'body')).to be_created
    expect(delete('/test')).to be_no_content
  end
  
  it 'should delete recursively' do
    expect(mkcol('/folder')).to be_created
    expect(put('/folder/a', {}, input: 'body')).to be_created
    expect(put('/folder/b', {}, input: 'body')).to be_created
    
    expect(delete('/folder')).to be_no_content
    expect(get('/folder')).to be_not_found
    expect(get('/folder/a')).to be_not_found
    expect(get('/folder/b')).to be_not_found
  end

  it 'should not allow copy to another domain' do
    expect(put('/test', {}, input: 'body')).to be_created
    expect(copy('http://example.org/', {}, {'HTTP_DESTINATION' => 'http://another/'})).to be_bad_gateway
  end

  it 'should not allow copy to the same resource' do
    expect(put('/test', {}, input: 'body')).to be_created
    expect(copy('/test', {}, {'HTTP_DESTINATION' => '/test'})).to be_forbidden
  end

  it 'should copy a single resource' do
    expect(put('/test', {}, input: 'body')).to be_created
    expect(copy('/test', {}, {'HTTP_DESTINATION' => '/copy'})).to be_created
    expect(get('/copy').body).to eq('body')
  end

  it 'should copy a resource with escaped characters' do
    expect(put(URI.escape('/a b'), {}, input: 'body')).to be_created
    expect(copy(URI.escape('/a b'), {}, {'HTTP_DESTINATION' => URI.escape('/a c')})).to be_created
    expect(get(URI.escape('/a c'))).to be_ok
    expect(last_response.body).to eq('body')
  end
  
  it 'should deny a copy without overwrite' do
    expect(put('/test', {}, input: 'body')).to be_created
    expect(put('/copy', {}, input: 'copy')).to be_created
    expect(copy('/test', {}, {'HTTP_DESTINATION' => '/copy', 'HTTP_OVERWRITE' => 'F'})).to be_precondition_failed
    expect(get('/copy').body).to eq('copy')
  end
  
  it 'should allow a copy with overwrite' do
    expect(put('/test', {}, input: 'body')).to be_created
    expect(put('/copy', {}, input: 'copy')).to be_created
    expect(copy('/test', {}, {'HTTP_DESTINATION' => '/copy', 'HTTP_OVERWRITE' => 'T'})).to be_no_content
    expect(get('/copy').body).to eq('body')
  end
  
  it 'should copy a collection' do
    expect(mkcol('/folder')).to be_created
    copy('/folder', {}, {'HTTP_DESTINATION' => '/copy'})
    expect(multi_status_created).to eq true
    propfind('/copy', {}, input: propfind_xml(:resourcetype))
    expect(multi_status_response('/D:propstat/D:prop/D:resourcetype/D:collection')).not_to be_empty
  end

  it 'should copy a collection resursively' do
    expect(mkcol('/folder')).to be_created
    expect(put('/folder/a', {}, input: 'A')).to be_created
    expect(put('/folder/b', {}, input: 'B')).to be_created
    
    copy('/folder', {}, {'HTTP_DESTINATION' => '/copy'})
    expect(multi_status_created).to eq true
    propfind('/copy', {}, input: propfind_xml(:resourcetype))
    expect(multi_status_response('/D:propstat/D:prop/D:resourcetype/D:collection')).not_to be_empty
    expect(get('/copy/a').body).to eq('A')
    expect(get('/copy/b').body).to eq('B')
  end
  
  it 'should move a collection recursively' do
    expect(mkcol('/folder')).to be_created
    expect(put('/folder/a', {}, input: 'A')).to be_created
    expect(put('/folder/b', {}, input: 'B')).to be_created
    
    move('/folder', {}, {'HTTP_DESTINATION' => '/move'})
    expect(multi_status_created).to eq true
    propfind('/move', {}, input: propfind_xml(:resourcetype))
    expect(multi_status_response('/D:propstat/D:prop/D:resourcetype/D:collection')).not_to be_empty    
    
    expect(get('/move/a').body).to eq('A')
    expect(get('/move/b').body).to eq('B')
    expect(get('/folder/a')).to be_not_found
    expect(get('/folder/b')).to be_not_found
  end
  
  it 'should create a collection' do
    expect(mkcol('/folder')).to be_created
    propfind('/folder', {}, input: propfind_xml(:resourcetype))
    expect(multi_status_response('/D:propstat/D:prop/D:resourcetype/D:collection')).not_to be_empty
  end
  
  it 'should return full urls after creating a collection' do
    expect(mkcol('/folder')).to be_created
    propfind('/folder', {}, input: propfind_xml(:resourcetype))
    expect(multi_status_response('/D:propstat/D:prop/D:resourcetype/D:collection')).not_to be_empty
    expect(multi_status_response('/D:href').first.text).to match(/http:\/\/example\.org(:\d+)?\/folder/)
  end
  
  it 'should not find properties for nonexistent resources' do
    expect(propfind('/non')).to be_not_found
  end
  
  it 'should find all properties' do
    xml = render(:propfind) do |xml|
      xml.allprop
    end
    
    propfind('http://example.org/', {}, input: xml)
    
    expect(multi_status_response('/D:href').first.text.strip).to match(/http:\/\/example\.org(:\d+)?\//)

    props = %w(creationdate displayname getlastmodified getetag resourcetype getcontenttype getcontentlength)
    props.each do |prop|
      expect(multi_status_response("/D:propstat/D:prop/D:#{prop}")).not_to be_empty
    end
  end
  
  it 'should find named properties' do
    expect(put('/test.html', {}, input: '<html/>')).to be_created
    propfind('/test.html', {}, input: propfind_xml(:getcontenttype, :getcontentlength))
   
    expect(multi_status_response('/D:propstat/D:prop/D:getcontenttype').first.text).to eq('text/html')
    expect(multi_status_response('/D:propstat/D:prop/D:getcontentlength').first.text).to eq('7')
  end

  it 'should lock a resource' do
    expect(put('/test', {}, input: 'body')).to be_created
    
    xml = render(:lockinfo) do |xml|
      xml.lockscope { xml.exclusive }
      xml.locktype { xml.write }
      xml.owner { xml.href "http://test.de/" }
    end

    lock('/test', {}, input: xml)
    
    expect(last_response).to be_ok
    
    match = lambda do |pattern|
      Nokogiri.XML(last_response.body).xpath "/D:prop/D:lockdiscovery/D:activelock#{pattern}"
    end
    
    expect(match['']).not_to be_empty

    expect(match['/D:locktype']).not_to be_empty
    expect(match['/D:lockscope']).not_to be_empty
    expect(match['/D:depth']).not_to be_empty
    expect(match['/D:timeout']).not_to be_empty
    expect(match['/D:locktoken']).not_to be_empty
    expect(match['/D:owner']).not_to be_empty
  end
  
  context "when mapping a path" do
    let(:controller) { DAV4Rack::Handler.new(root: TEST_ROOT_DIRECTORY, root_uri_path: '/webdav/') }

    it "should return correct urls" do
      # FIXME: a put to '/test' works, too -- should it?
      expect(put('/webdav/test', {}, input: 'body')).to be_created
      expect(last_response.headers['location']).to match(/http:\/\/example\.org(:\d+)?\/webdav\/test/)
    end
  end
end
