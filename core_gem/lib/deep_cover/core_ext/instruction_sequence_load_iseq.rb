# frozen_string_literal: true

module DeepCover
  load_all

  module InstructionSequenceLoadIseq
    def load_iseq(path)
      compiled = InstructionSequenceLoadIseq.load_iseq_logic(path)

      return compiled if compiled

      # By default there is no super, but if bootsnap is there, and things are in the right order,
      # we could possibly fallback to it as usual to keep the perf gain. Same for other possible
      # tools using #load_iseq
      super if defined?(super)
    end

    def self.load_iseq_logic(path)
      return unless DeepCover.running?
      return unless DeepCover.tracked_file_path?(path)

      covered_code = DeepCover.coverage.covered_code_or_warn(path)
      return unless covered_code

      covered_code.compile_or_warn
    end
  end
end

class << RubyVM::InstructionSequence
  prepend DeepCover::InstructionSequenceLoadIseq
end
