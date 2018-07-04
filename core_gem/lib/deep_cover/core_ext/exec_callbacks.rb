# frozen_string_literal: true

require_relative '../module_override'

# Adds a functionality to add callbacks before an `exec`

module DeepCover
  module ExecCallbacks
    class << self
      attr_reader :callbacks

      def before_exec(&block)
        self.active = true
        (@callbacks ||= []) << block
      end
    end

    def exec(*args)
      ExecCallbacks.callbacks.each(&:call)
      exec_without_deep_cover(*args)
    end

    extend ModuleOverride
    override ::Kernel, ::Kernel.singleton_class
    self.active = true
  end
end
