# frozen_string_literal: true

module DeepCover
  module Load
    AUTOLOAD = %i[analyser auto_run config
                  coverage covered_code custom_requirer
                  flag_comment_associator memoize module_override node
                  problem_with_diagnostic reporter tracker_bucket
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
      Object.autoload :Bundler, 'bundler'
      Object.autoload :YAML, 'yaml'
    end

    def bootstrap
      @bootstrapped ||= false # Avoid warning
      return if @bootstrapped
      require_relative 'backports'
      require_relative 'tools'
      @bootstrapped = true
    end

    def load_parser
      @parser_loaded ||= false # Avoid warning
      return if @parser_loaded
      silence_warnings do
        require 'parser'
        require 'parser/current'
      end
      require_relative_dir 'parser_ext'
      @parser_loaded = true
    end

    def load_pry
      silence_warnings do # Avoid "WARN: Unresolved specs during Gem::Specification.reset"
        require 'pry'     # after `pry` calls `Gem.refresh`
      end
    end

    def load_all
      @all_loaded ||= false
      return if @all_loaded
      bootstrap
      load_parser
      AUTOLOAD.each do |module_name|
        DeepCover.const_get(Tools::Camelize.camelize(module_name))
      end
      DeepCover.const_get(:VERSION)
      @all_loaded = true
    end
  end

  extend Load
end
