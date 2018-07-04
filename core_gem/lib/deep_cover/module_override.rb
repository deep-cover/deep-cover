# frozen_string_literal: true

module DeepCover
  # Helps redefine methods in overriden_modules.
  # For each methods in Mod, this defines `<method>_with{out}_deep_cover`.
  # Set `active` to true or false to alias <method> to one or the other.
  module ModuleOverride
    attr_reader :overriden_modules

    def active=(active)
      each do |mod, method_name|
        mod.send :alias_method, method_name, :"#{method_name}_#{active ? 'with' : 'without'}_deep_cover"
        if mod == ::Kernel
          mod.send :private, method_name
        end
      end
    end

    def override(*modules)
      @overriden_modules = modules
      each do |mod, method_name|
        mod.send :alias_method, :"#{method_name}_without_deep_cover", method_name
        mod.send :define_method, :"#{method_name}_with_deep_cover", instance_method(method_name)
        if mod == ::Kernel
          mod.send :private, :"#{method_name}_without_deep_cover"
          mod.send :private, :"#{method_name}_with_deep_cover"
        end
      end
    end

    def each(&block)
      overriden_modules.each do |mod|
        instance_methods(false).each do |method_name|
          yield mod, method_name
        end
      end
    end
  end
end
