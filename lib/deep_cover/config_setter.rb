# frozen_string_literal: true

module DeepCover
  module ConfigSetter
    def config(notify = self)
      @config ||= Config.new(notify)
    end

    def configure(&block)
      raise 'Must provide a block' unless block
      case block.arity
      when 0
        config.instance_eval(&block)
      when 1
        block.call(config)
      end
    end
  end
end
