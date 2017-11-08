module DeepCover
  module Tools::BuiltinCoverage
    # module/class
    def all_modules_under(mod)
      to_see = [mod]
      seen_modules = Set.new
      until to_see.empty?
        mod = to_see.shift
        next if seen_modules.include?(mod)
        seen_modules << mod

        objects = mod.constants.map{|c| mod.const_get(c)}.uniq
        objects.select! { |o| o.is_a?(Module) }
        objects.reject! { |o| seen_modules.include?(o) }

        to_see.concat(objects)
      end
      seen_modules.to_a
    end

    def all_node_classes
      all_modules_under(DeepCover::Node).select{|m| m < DeepCover::Node}
    end
  end
end
