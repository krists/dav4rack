# frozen_string_literal: true

require File.expand_path("../lib/dav4rack/version", __FILE__)

Gem::Specification.new do |s|
  s.name = 'dav4rack'
  s.version = DAV4Rack::VERSION
  s.summary = 'WebDAV handler for Rack'
  s.author = 'Chris Roberts'
  s.email = 'chrisroberts.code@gmail.com'
  s.homepage = 'http://github.com/chrisroberts/dav4rack'
  s.description = 'WebDAV handler for Rack'
  s.bindir        = "exe"
  s.executables   = ["dav4rack"]
  s.require_paths = ["lib"]
  s.add_dependency 'nokogiri', '~> 1.10.3'
  s.add_dependency 'uuidtools', '~> 2.1.1'
  s.add_dependency 'rack', '~> 1.6.11'
  s.files = Dir["lib/**/*.rb", "exe/dav4rack"]
end
