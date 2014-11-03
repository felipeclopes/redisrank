# add project-relative load paths
$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require 'simplecov'
SimpleCov.start do
  add_filter '/spec'
  add_filter '/vendor'
end

# require stuff
require 'redisrank'
require 'rspec'
require 'rspec/autorun'

# use the test Redisrank instance
Redisrank.connect(:port => 8379, :db => 15, :thread_safe => true)
Redisrank.redis.flushdb
