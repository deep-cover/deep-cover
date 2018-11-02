# frozen_string_literal: true

# This file is required by absolute path in the entry_points when doing clone mode.
# THERE MUST NOT BE ANY USE/REQUIRE OF DEPENDENCIES OF DeepCover HERE
# See deep-cover/core_gem/lib/deep_cover/setup/clone_mode_entry.rb for details

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
