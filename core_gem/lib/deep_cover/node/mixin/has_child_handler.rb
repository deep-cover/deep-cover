# frozen_string_literal: true

module DeepCover
  module Node::Mixin
    module HasChildHandler
      def self.included(base)
        base.extend ClassMethods
      end

      def call_child_handler(template, child, child_name = nil)
        child_name ||= self.child_index_to_name(child.index)
        method_name = format(template, name: child_name)
        if respond_to?(method_name)
          args = [child, child_name]
          arity = method(method_name).arity
          if arity >= 0
            args = args[0...arity]
          end
          answer = send(method_name, *args)
        end
        answer
      end
      private :call_child_handler

      module ClassMethods
        def has_child_handler(template)
          child_method_name = format(template, name: 'child')
          action = template.gsub(/_%{name}/, '').gsub(/%{name}_/, '')
          const_name = "#{Tools.camelize(action)}Handler"
          class_eval <<-EVAL, __FILE__, __LINE__ + 1
            module #{const_name}                                     # module RewriteHandler
              module ClassMethods                                    #   module ClassMethods
                def has_child(#{action}: nil, **args)                #     def has_child(rewrite: nil, **args)
                  name, _types = args.first                          #       name, _types = args.first
                  define_child_handler(#{template.inspect},          #       define_child_handler('rewrite_%{child}',
                    name, #{action})                                 #         name, rewrite)
                  super(**args)                                      #       super(**args)
                end                                                  #     end
              end                                                    #   end

              def #{child_method_name}(child, name = nil)            #   def rewrite_child(child, name = nil)
                call_child_handler(#{template.inspect}, child,       #     call_child_handler('rewrite_%{child}', child,
                  name) || super                                     #       name) || super
              end                                                    #   end
            end                                                      # end
            include #{const_name}                                    # include RewriteHandler
            singleton_class.prepend #{const_name}::ClassMethods      # singleton_class.prepend RewriteHandler::ClassMethods
          EVAL
        end

        def define_child_handler(template, name, action)
          method_name = format(template, name: name)
          case action
          when nil
            # Nothing to do
          when Symbol
            define_method(method_name) do |*args|
              arity = method(action).arity
              raise NotImplementedError if arity < 0
              send(action, *args[0...arity])
            end
          when Proc
            define_method(method_name, &action)
          else
            define_method(method_name) { |*| action }
          end
        end
        private :define_child_handler
      end
    end
  end
end
