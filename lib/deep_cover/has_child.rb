module DeepCover
  module HasChild
    def self.included(base)
      base.extend ClassMethods
    end

    module ClassMethods
      # Creates methods to return the children corresponding with the given `names`,
      # alias for `next_instruction`.
      # Also creates constants for the indices of the children.
      def has_children(*names, next_instruction: false)
        map = {}
        i = 0
        names.each do |name|
          if name.to_s.end_with?('__rest')
            name = name.to_s.gsub(/__rest$/, '')
            nb_after = names.size - i - 1
            map[name] = i..(-1-nb_after)

            # Now we cound from the end
            i = -nb_after
          else
            map[name] = i
            i += 1
          end
        end

        map.each do |name, i|
          class_eval <<-end_eval, __FILE__, __LINE__
            def #{name}
              children[#{i}]
            end
            #{name.upcase} = #{i}
          end_eval
        end
        alias_method :next_instruction, next_instruction if next_instruction
        const_set :CHILDREN, map
      end
    end
  end
end
