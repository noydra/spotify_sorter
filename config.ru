require 'rubygems'
require 'bundler/setup'
Bundler.require

require './app'

# Force HTTPS in production
use Rack::SslEnforcer if ENV['RACK_ENV'] == 'production'

# Support for running behind a proxy/load balancer
use Rack::ReverseProxy if defined?(Rack::ReverseProxy)

run Sinatra::Application
