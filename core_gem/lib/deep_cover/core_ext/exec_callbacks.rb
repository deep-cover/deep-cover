# frozen_string_literal: true

# Adds a functionality to add callbacks before an `exec`

module DeepCover
  module ExecCallbacks
    class << self
      attr_reader :callbacks

      def before_exec(&block)
        (@callbacks ||= []) << block
      end
    end
  end

  [::Kernel, ::Kernel.singleton_class].each do |mod|
    mod.send(:alias_method, :exec_without_deep_cover, :exec)
    mod.send(:define_method, :exec) do |*args|
      ExecCallbacks.callbacks.each(&:call)
      exec_without_deep_cover(*args)
    end
  end
  ::Kernel.send :private, :exec_without_deep_cover
end
