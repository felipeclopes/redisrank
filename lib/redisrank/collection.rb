module Redisrank
  class Collection < ::Array

    attr_accessor :from
    attr_accessor :till
    attr_accessor :depth
    attr_accessor :rank

    def initialize(options = {})
      @from = options[:from] ||= nil
      @till = options[:till] ||= nil
      @depth = options[:depth] ||= nil
    end

    def rank
      @rank ||= {}
    end

  end
end
