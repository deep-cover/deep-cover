# frozen_string_literal: true

# This file is used by projects cloned with clone mode. As such, special care must be taken to
# be compatible with any projects.
# THERE MUST NOT BE ANY USE/REQUIRE OF DEPENDENCIES OF DeepCover HERE
# See deep-cover/core_gem/lib/deep_cover/setup/clone_mode_entry_template.rb for explanation of
# clone mode and of this top_level_module stuff.
top_level_module = Thread.current['_deep_cover_top_level_module'] || Object # rubocop:disable Lint/UselessAssignment

# Adds a functionality to add callbacks before an `exec`

module top_level_module::DeepCover # rubocop:disable Naming/ClassAndModuleCamelCase
  module ExecCallbacks
    class << self
      attr_reader :callbacks

      def before_exec(&block)
        (@callbacks ||= []) << block
      end
    end
  end

  # We use #object_id of DeepCover to avoid possible overwrite between clone-mode and non-clone-mode
  original_exec_name = :"exec_without_deep_cover_#{self.object_id}"
  [::Kernel, ::Kernel.singleton_class].each do |mod|
    mod.send(:alias_method, original_exec_name, :exec)
    mod.send(:define_method, :exec) do |*args|
      ExecCallbacks.callbacks.each(&:call)
      send(original_exec_name, *args)
    end
  end
  ::Kernel.send :private, original_exec_name
end
