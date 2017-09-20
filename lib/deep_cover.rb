require "parser"
require 'active_support/core_ext/module/delegation'

module DeepCover
  def self.require_relative_dir(dir_name)
    dir = File.dirname(caller.first.partition(/\.rb:\d/).first)
    Dir["#{dir}/#{dir_name}/*.rb"].sort.each do |file|
      require file
    end
  end

  require_relative_dir 'deep_cover'

  class << self
    def start
      require_relative 'deep_cover/core_ext/require_overrides'
    end

    def line_coverage(filename)
      cover.line_coverage(filename)
    end

    def covered_code(filename)
      cover.covered_code(filename)
    end

    def cover
      @cover ||= Coverage.new
    end

    def custom_requirer
      @custom_requirer = CustomRequirer.new
    end
  end
end
DeepCover::GLOBAL_BINDING = binding
