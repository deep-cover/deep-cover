# frozen_string_literal: true

# This file is executed only when deep_cover is covering itself.

DeepCover.configure do
  tracker_global '$_dcg'
  ignore_uncovered :warn, :raise, :default_argument
  # Statement analyser is only used for Istanbul output and is undertested.
  # Ignore for now. TODO: test this, or get rid of StatementAnalyser
  ignore_uncovered :is_statement_methods do
    parent.is_a?(DeepCover::Node::Def) && parent.method_name == :is_statement
  end
end
