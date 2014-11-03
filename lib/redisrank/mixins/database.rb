module Redisrank
  module Database
    def self.included(base)
      base.extend(Database)
    end
    def db(ref = nil)
      ref ||= @options[:connection_ref] if !@options.nil?
      Redisrank.connection(ref)
    end
  end
end
