# frozen_string_literal: true

module DeepCover
  module Node::Mixin
    module Filters
      module ClassMethods
        def filter_to_method_name(kind)
          :"is_#{kind}?"
        end
      end

      RAISING_MESSAGES = %i[raise exit].freeze
      def is_raise?
        is_a?(Node::Send) && RAISING_MESSAGES.include?(message) && receiver == nil
      end

      def is_default_argument?
        parent.is_a?(Node::Optarg)
      end

      def is_case_implicit_else?
        is_a?(Node::EmptyBody) && parent.is_a?(Node::Case) && !parent.has_else?
      end

      def is_trivial_if?
        # Supports only node being a branch or the fork itself
        parent.is_a?(Node::If) && parent.condition.is_a?(Node::SingletonLiteral)
      end
    end
  end
end
