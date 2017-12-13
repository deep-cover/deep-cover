# frozen_string_literal: true

module DeepCover
  bootstrap

  # An analyser works on a subset of the original Node AST.
  # The Root node is always considered part of the subset.
  # One can iterate this subset with `each_node`, or ask
  # the analyser for information about a node's children
  # (i.e. with respect to this subset), or runs for any node
  # in this subset.

  # An analyser can summarize information with `results`.
  # While CoveredCodeSource is based on a CoveredCode, all
  # other analysers are based on another source analyser.

  class Analyser
  end

  require_relative_dir 'analyser'

  Analyser.include Analyser::Base
end
