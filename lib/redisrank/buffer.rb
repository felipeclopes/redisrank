require 'redisrank/core_ext/hash'

module Redisrank
  class Buffer
    include Synchronize

    def self.instance
      @instance ||= self.new
    end

    def size
      synchronize do
        @size ||= 0
      end
    end

    def size=(value)
      synchronize do
        @size = value
      end
    end

    def count
      @count ||= 0
    end

    def store(key, stats, depth_limit, opts)
      return false unless should_buffer?

      to_flush = {}
      buffkey = buffer_key(key, opts)

      synchronize do
        if !queue.has_key?(buffkey)
          queue[buffkey] = { :key         => key,
                             :stats       => {},
                             :depth_limit => depth_limit,
                             :opts        => opts }
        end

        queue[buffkey][:stats].merge_to_max!(stats)
        incr_count

        # return items to be flushed if buffer size limit has been reached
        to_flush = reset_queue
      end

      # flush any data that's been cleared from the queue
      flush_data(to_flush)
      true
    end

    def flush(force = false)
      to_flush = {}
      synchronize do
        to_flush = reset_queue(force)
      end
      flush_data(to_flush)
    end

    private

    # should always be called from within a synchronize block
    def incr_count
      @count ||= 0
      @count += 1
    end

    def queue
      @queue ||= {}
    end

    def should_buffer?
      size > 1 # buffer size of 1 would be equal to not using buffer
    end

    # should always be called from within a synchronize block
    def should_flush?
      (!queue.blank? && count >= size)
    end

    # returns items to be flushed if buffer size limit has been reached
    # should always be called from within a synchronize block
    def reset_queue(force = false)
      return {} if !force && !should_flush?
      data = queue
      @queue = {}
      @count = 0
      data
    end

    def flush_data(buffer_data)
      buffer_data.each do |k, item|
        Summary.update(item[:key], item[:stats], item[:depth_limit], item[:opts])
      end
    end

    # depth_limit is not needed as it's evident in key.to_s
    def buffer_key(key, opts)
      # covert keys to strings, as sorting a Hash with Symbol keys fails on
      # Ruby 1.8.x.
      opts = opts.inject({}) do |result, (k, v)|
        result[k.to_s] = v
        result
      end
      "#{key.to_s}:#{opts.sort.flatten.join(':')}"
    end

  end
end
