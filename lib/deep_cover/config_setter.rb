# frozen_string_literal: true

module DeepCover
  module ConfigSetter
    def config_queue
      @config_queue ||= []
    end

    def config(notify = self)
      @config ||= Config.new(notify)
      config_queue.each { |block| configure(&block) }
      config_queue.clear
      @config
    end

    def configure(&block)
      raise 'Must provide a block' unless block
      @config ||= nil # avoid warning
      if @config == nil
        config_queue << block
      else
        case block.arity
        when 0
          @config.instance_eval(&block)
        when 1
          block.call(@config)
        end
      end
      self
    end
  end
end
