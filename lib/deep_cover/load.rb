# frozen_string_literal: true

module DeepCover
  module Load
    AUTOLOAD = %i[analyser autoload_tracker auto_run config
                  coverage covered_code custom_requirer
                  flag_comment_associator memoize module_override node
                  problem_with_diagnostic reporter
                 ]

    def load_absolute_basics
      require_relative 'base'
      require_relative 'basics'
      require_relative 'config_setter'
      require_relative 'tools/camelize'
      AUTOLOAD.each do |module_name|
        DeepCover.autoload(Tools::Camelize.camelize(module_name), "#{__dir__}/#{module_name}")
      end
      DeepCover.autoload :VERSION, 'deep_cover/version'
      Object.autoload :Term, 'term/ansicolor'
      Object.autoload :Terminal, 'terminal-table'
      Object.autoload :YAML, 'yaml'
      require 'pry'
    end

    def bootstrap
      return if @bootstrapped
      require_relative 'backports'
      require_relative 'tools'
      @bootstrapped = true
    end

    def load_parser
      return if @parser_loaded
      require 'parser'
      silence_warnings do
        require 'parser/current'
      end
      require 'parser_tree_rewriter'
      require_relative_dir 'parser_ext'
      @parser_loaded
    end

    def load_all
      return if @all_loaded
      bootstrap
      load_parser
      AUTOLOAD.each do |module_name|
        DeepCover.const_get(Tools::Camelize.camelize(module_name))
      end
      DeepCover::VERSION # rubocop:disable Lint/Void
      @all_loaded = true
    end
  end

  extend Load
end
