# frozen_string_literal: true

module DeepCover
  module Load
    AUTOLOAD = %i[analyser autoload_tracker auto_run config
                  coverage covered_code custom_requirer
                  flag_comment_associator global_variables memoize module_override node
                  persistence problem_with_diagnostic reporter
                 ]

    def load_absolute_basics
      require_relative 'base'
      require_relative 'basics'
      require_relative 'config_setter'
      require_relative 'tools/camelize'
      require_relative 'tools/ruby_engines'
      DeepCover.extend(Tools::RubyEngines)
      Tools.extend(Tools::RubyEngines)

      AUTOLOAD.each do |module_name|
        DeepCover.autoload(Tools::Camelize.camelize(module_name), "#{__dir__}/#{module_name}")
      end
      DeepCover.autoload :VERSION, "#{__dir__}/version"

      Object.autoload :Forwardable, 'forwardable'
      Object.autoload :YAML, 'yaml'

      # In ruby 2.2 and in JRuby, autoload doesn't work for gems which are not already on the `$LOAD_PATH`.
      # The fix is to just require right away for those rubies
      # JRuby issue asking for this to be changed: https://github.com/jruby/jruby/issues/5403
      #
      # Low-level: autoload not working for gems not on the `$LOAD_PATH` is because those rubies don't
      # call the regular `#require` when triggering an autoload, and the gem system monkey-patches `#require`
      # so that when a file is not found in the `$LOAD_PATH`, but can be found in an existing gem, that gem's
      # path is added to the `$LOAD_PATH`
      {JSON: 'json',
       Term: 'term/ansicolor',
       Terminal: 'terminal-table',
      }.each do |const, require_path|
        if RUBY_VERSION < '2.3' || RUBY_PLATFORM == 'java'
          require require_path
        else
          Object.autoload const, require_path
        end
      end
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
      Tools.silence_warnings do
        require 'parser'
        require 'parser/current'
      end
      require_relative_dir 'parser_ext'
      @parser_loaded = true
    end

    def load_pry
      Tools.silence_warnings do # Avoid "WARN: Unresolved specs during Gem::Specification.reset"
        require 'pry'           # after `pry` calls `Gem.refresh`
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
