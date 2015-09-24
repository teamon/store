require "rack"
require "rack/cors"
require "redis"

# lib
class App
  attr_reader :redis

  def initialize(redis)
    @redis = redis
  end

  def call(env)
    status, headers, body = _call(env)
    [status, headers, body.lines]
  end

  protected

  def _call(env)
    if method_allowed?(env)
      if key = parse_key(env)
        process(key, env)
      else
        bad_request
      end
    else
      method_not_supported
    end
  end

  def process(key, env)
    case env["REQUEST_METHOD"]
    when "GET"
      if value = redis.get(key)
        ok(value)
      else
        not_found
      end
    when "PUT"
      value = env["rack.input"].read
      redis.set(key, value)
      ok("")
    end
  end

  def parse_key(env)
    env["REQUEST_PATH"].split("/").drop_while(&:empty?).first
  end

  def method_allowed?(env)
    ["GET", "PUT"].include?(env["REQUEST_METHOD"])
  end

  def ok(body, headers = {})
    [200, headers, body]
  end

  def method_not_supported
    [405, {}, "Method Not Supported"]
  end

  def bad_request
    [422, {}, "Bad Request"]
  end

  def not_found
    [404, {}, "Not Found"]
  end
end

# wire
redis = Redis.new(url: ENV.fetch("REDIS_URL") { "redis://localhost:6379/0"})
app   = App.new(redis)

# rack
use Rack::Cors do
  allow do
    origins '*'
    resource '*', :headers => :any, :methods => [:get, :put]
  end
end

run app
