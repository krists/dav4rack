module RequestHelper
  include Rack::Test::Methods

  def app
    builder = Rack::Builder.new
    builder.run controller
  end

  %w(PROPFIND PROPPATCH MKCOL COPY MOVE LOCK UNLOCK).each do |method|
    define_method(method.downcase) do |uri, params = {}, env = {}, &block|
      custom_request(method, uri, params, env, &block)
    end
  end
end

RSpec.configure do |c|
  c.include RequestHelper
end
