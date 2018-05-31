# frozen_string_literal: true

require 'spec_helper'

module DeepCover
  RSpec.describe 'AutoloadOverride' do
    def setup_deep_covered_script(ruby_code)
      deep_cover_path = File.absolute_path('../lib/deep-cover', __dir__)
      ruby_code = <<-RUBY
        require #{deep_cover_path.inspect}
        DeepCover.start

        #{ruby_code}
        puts 'Done'
      RUBY

      @script_file = Tempfile.new(['autoload_test', '.rb'])
      @script_file.write(ruby_code)
      @script_file.close
    end

    def assert_script_runs(script_file: @script_file)
      ['ruby', script_file.path].should run_successfully.from_dir(File.dirname(script_file.path)).and_output('Done')
    end

    it 'handles manual require of autoloaded bundler which is not yet on the LOAD_PATH (but bunder is builtin to RubyGems)' do
      setup_deep_covered_script(<<-RUBY)
        Object.autoload(:Bundler, 'bundler')
        require 'bundler'
      RUBY

      assert_script_runs
    end

    it 'handles autoload of bundler which not yet on the LOAD_PATH (but bunder is builtin to RubyGems)' do
      setup_deep_covered_script(<<-RUBY)
        Object.autoload(:Bundler, 'bundler')
        Bundler
      RUBY

      assert_script_runs
    end

    it 'handles manual require of autoloaded gems which are not yet on the LOAD_PATH' do
      setup_deep_covered_script(<<-RUBY)
        Object.autoload(:Slop, 'slop')
        require 'slop'
      RUBY

      assert_script_runs
    end

    it 'handles autoload of gem which are not yet on the LOAD_PATH' do
      setup_deep_covered_script(<<-RUBY)
        Object.autoload(:Slop, 'slop')
        Slop
      RUBY

      assert_script_runs
    end
  end
end
