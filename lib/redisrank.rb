
require 'rubygems'
require 'date'
require 'time'
require 'digest/sha1'
require 'monitor'

# Active Support 2.x or 3.x
require 'active_support'
if !{}.respond_to?(:with_indifferent_access)
  require 'active_support/core_ext/hash/indifferent_access'
  require 'active_support/core_ext/hash/reverse_merge'
end

require 'time_ext'
require 'redis'
require 'json'

require 'redisrank/mixins/options'
require 'redisrank/mixins/synchronize'
require 'redisrank/mixins/database'
require 'redisrank/mixins/date_helper'

require 'redisrank/connection'
require 'redisrank/buffer'
require 'redisrank/collection'
require 'redisrank/date'
require 'redisrank/event'
require 'redisrank/finder'
require 'redisrank/key'
require 'redisrank/label'
require 'redisrank/model'
require 'redisrank/result'
require 'redisrank/scope'
require 'redisrank/summary'
require 'redisrank/version'

require 'redisrank/core_ext'


module Redisrank

  KEY_NEXT_ID = ".next_id"
  KEY_EVENT = ".event:"
  KEY_LABELS = "Redisrank.labels:" # used for reverse label hash lookup
  KEY_EVENT_IDS = ".event_ids"
  LABEL_INDEX = ".label_index:"
  GROUP_SEPARATOR = "/"

  class InvalidOptions < ArgumentError; end
  class RedisServerIsTooOld < Exception; end

  class << self

    def buffer
      Buffer.instance
    end

    def buffer_size
      buffer.size
    end

    def buffer_size=(size)
      buffer.size = size
    end

    def thread_safe
      Synchronize.thread_safe
    end

    def thread_safe=(value)
      Synchronize.thread_safe = value
    end

    def connection(ref = nil)
      Connection.get(ref)
    end
    alias :redis :connection

    def connection=(connection)
      Connection.add(connection)
    end
    alias :redis= :connection=

    def connect(options)
      Connection.create(options)
    end

    def flush
      puts "WARNING: Redisrank.flush is deprecated. Use Redisrank.redis.flushdb instead."
      connection.flushdb
    end

    def group_separator
      @group_separator ||= GROUP_SEPARATOR
    end
    attr_writer :group_separator

  end
end


# ensure buffer is flushed on program exit
Kernel.at_exit do
  Redisrank.buffer.flush(true)
end
