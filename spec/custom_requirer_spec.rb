# frozen_string_literal: true

require 'spec_helper'

module DeepCover
  RSpec.describe CustomRequirer do
    let(:lookup_paths) { ['/'] }
    let(:requirer) { CustomRequirer.new(load_paths: [], loaded_features: [], lookup_paths: lookup_paths) }
    before(:each) { $last_test_tree_file_executed = nil }
    around(:each) do |ex|
      begin
        dir = Dir.mktmpdir('deep_cover_test')
        # Ensure presence of a separator at the end of the string
        @root = File.join(dir, '')

        current_pwd = Dir.pwd
        ex.run
      ensure
        Dir.chdir(current_pwd)
        FileUtils.remove_entry dir
      end
    end

    matcher :actually_require do |expected_executed_file, **options|
      match do |require_path|
        @result = {}
        @executed_file = {}
        @loaded_features = {}

        set_expectations(expected_executed_file, options[:expected_loaded_feature])

        run_ruby_require(require_path)
        run_custom_require(require_path)

        # At the moment, the only case of not_supported is when a .so file is found
        @result[:custom] = :file_extension_is_so if @result[:custom] == :not_supported

        %w(result executed_file loaded_features).all? do |value_name|
          values = instance_variable_get("@#{value_name}").values
          values.delete(:skip_this)
          values.all? { |v| v == values[0] }
        end
      end

      failure_message do |require_path|
        [
          "Unexpected effects of `require #{require_path.inspect}`:",
          'Return value:',
          build_output(@result),
          '',
          'Executed file:',
          build_output(@executed_file),
          '',
          'Loaded features:',
          build_output(@loaded_features),
        ].join("\n")
      end

      def set_expectations(expected_executed_file, expected_loaded_feature)
        case expected_executed_file
        when Symbol
          @executed_file[:expected] = nil
          @result[:expected] = expected_executed_file
        when String
          @executed_file[:expected] = expected_executed_file
          @result[:expected] = true
        when false
          @executed_file[:expected] = nil
          @result[:expected] = false
        else
          raise
        end
        @loaded_features[:expected] = requirer.loaded_features.dup
        if expected_executed_file.is_a?(String)
          expected_loaded_feature ||= expected_executed_file
          @loaded_features[:expected] += [from_root(expected_loaded_feature)]
        end
      end

      # Must be run before run_custom_require
      def run_ruby_require(require_path)
        $last_test_tree_file_executed = nil
        # Test ruby require
        begin
          tmp_load_path = $LOAD_PATH.dup
          $LOAD_PATH[0..-1] = requirer.load_paths
          tmp_loaded_features = $LOADED_FEATURES.dup
          $LOADED_FEATURES[0..-1] = requirer.loaded_features
          @result[:ruby] = require(require_path)
        rescue LoadError => e
          if e.message[/file too short/]
            @result[:ruby] = :file_extension_is_so
          else
            @result[:ruby] = :not_found
          end
        ensure
          @loaded_features[:ruby] = $LOADED_FEATURES.dup
          $LOAD_PATH[0..-1] = tmp_load_path
          $LOADED_FEATURES[0..-1] = tmp_loaded_features
        end
        @executed_file[:ruby] = $last_test_tree_file_executed
      end

      def run_custom_require(require_path)
        $last_test_tree_file_executed = nil
        @result[:custom] = custom_require_or_reason(require_path)
        @loaded_features[:custom] = requirer.loaded_features.dup
        @executed_file[:custom] = $last_test_tree_file_executed
      end

      def build_output(data_hash)
        keys = [:expected, :ruby, :custom]
        max_ley_length = keys.map(&:size).max
        keys.map do |key|
          indent = ' ' * (max_ley_length - key.size)
          "  #{key}:#{indent} #{data_hash[key].inspect}"
        end.join("\n")
      end
    end

    # This cannot be a `let` because we want to be able to change it
    def root
      Pathname.new(@root).realpath.to_s
    end

    def add_load_path(path)
      requirer.load_paths << from_root(path)
    end

    def file_tree(tree_entries)
      Specs.file_tree(root, tree_entries)
    end

    def from_root(path)
      File.absolute_path(path, root)
    end

    def custom_require_or_reason(path)
      requirer.require(path) { |reason| reason }
    end

    describe '#require' do
      # TOMA: Pretty much all of those case could be repeated as-is, except for adding a .rb to the require's path.
      #       A lot of these tests could be make for #load also, minus the loaded_features check. What do you think?
      #       In the case of #load, the tests could again be repeated as it (with/without .rb), except now, the without
      #           .rb should just always fail unless a file matches it.
      #       In every test, I have a few extra directories/files, is that dumb?
      #
      #
      it 'handles a ./path relatively to current work dir' do
        file_tree %w(pwd:one/two/
                     one/two/test.rb
                     one/two/three/test.rb
                    )

        './test'.should actually_require('one/two/test.rb')
      end

      it 'handles a Pathname instance' do
        file_tree %w(pwd:one/two/
                     one/two/test.rb
                     one/two/three/test.rb
                    )

        Pathname('./test').should actually_require('one/two/test.rb')
      end

      it 'a ./path ignores the load_path' do
        file_tree %w(one/two/test.rb
                     one/two/three/test.rb
                    )

        add_load_path 'one/two'
        './test'.should actually_require(:not_found)
      end

      it 'handles a ../path relatively to current work dir' do
        file_tree %w(pwd:one/two/
                     one/test.rb
                     one/two/test.rb
                     one/two/three/test.rb
                    )

        '../test'.should actually_require('one/test.rb')
      end

      it 'a ../path ignores the load_path' do
        file_tree %w(one/two/test.rb
                     one/two/three/test.rb
                    )
        add_load_path 'one/two/three'

        '../test'.should actually_require(:not_found)
      end

      it 'a /../ in a path after a name will go to the parent' do
        file_tree %w(one/test.rb
                     one/two/test.rb
                     one/two/three/test.rb
                    )
        add_load_path 'one'

        'two/../test'.should actually_require('one/test.rb')
      end

      it 'a /./ in a path after a name will be ignored ' do
        file_tree %w(one/test.rb
                     one/two/test.rb
                     one/two/three/test.rb
                    )
        add_load_path 'one'

        'two/./test'.should actually_require('one/two/test.rb')
      end

      it 'Can go to parent of load_path with multiple /../' do
        file_tree %w(one/test.rb
                     one/two/test.rb
                     one/two/three/test.rb
                    )
        add_load_path 'one/two'

        'three/../../test'.should actually_require('one/test.rb')
      end

      it 'finds files with directories in the required path' do
        file_tree %w(one/test.rb
                     one/two/test.rb
                     one/two/three/test.rb
                    )
        add_load_path 'one'

        'two/three/test'.should actually_require('one/two/three/test.rb')
      end

      it 'uses the matching file from the the first matching load_path' do
        file_tree %w(one/test.rb
                     one/two/test.rb
                     one/two/three/test.rb
                    )
        add_load_path 'one'
        add_load_path 'one/two'
        add_load_path 'one/two/three'

        'test'.should actually_require('one/test.rb')
      end

      # TOMA: Is that a useless test?
      it "doesn't use a wrong file form the matching directly" do
        file_tree %w(one/test.rb
                     one/two/abc.rb
                     one/two/test.rb
                     one/two/zyx.rb
                     one/two/three/test.rb
                    )
        add_load_path 'one/two'

        'test'.should actually_require('one/two/test.rb')
      end

      it "doesn't execute a file that was already required" do
        file_tree %w(one/test.rb
                     one/two/test.rb
                     one/two/three/test.rb
                    )
        add_load_path 'one'
        add_load_path 'one/two'
        add_load_path 'one/two/three'
        requirer.loaded_features << from_root('one/test.rb')

        'test'.should actually_require(false)
      end

      it "doesn't execute a file that was already required through another load_path" do
        file_tree %w(one/test.rb
                     one/two/test.rb
                     one/two/three/test.rb
                    )
        add_load_path 'one/two'
        'test'.should actually_require('one/two/test.rb')

        add_load_path 'one'
        'two/test'.should actually_require(false)
      end

      it "doesn't find from parent or subdir of the load_path" do
        file_tree %w(one/test.rb
                     one/two/three/test.rb
                    )
        add_load_path 'one/two'

        'test'.should actually_require(:not_found)
      end

      it 'regular path ignores current work dir' do
        file_tree %w(one/test.rb
                     pwd:one/two/
                     one/two/test.rb
                     one/two/three/test.rb
                    )

        'test'.should actually_require(:not_found)
      end

      it 'ignores a not .rb file when path includes .rb' do
        file_tree %w(one/test.rb
                     one/two/test
                     one/two/three/test.rb
                    )
        add_load_path 'one/two'

        'test.rb'.should actually_require(:not_found)
      end

      it 'ignores a not .rb file when path is without .rb' do
        file_tree %w(one/test.rb
                     one/two/test
                     one/two/three/test.rb
                    )
        add_load_path 'one/two'

        'test'.should actually_require(:not_found)
      end

      it 'accepts an absolute .rb file with absolute path without .rb' do
        file_tree %w(one/two/test.rb)

        File.join(root, 'one/two/test').should actually_require('one/two/test.rb')
      end

      it 'accepts an absolute .rb file with absolute path with .rb' do
        file_tree %w(one/two/test.rb)

        File.join(root, 'one/two/test.rb').should actually_require('one/two/test.rb')
      end

      it 'ignores an absolute not .rb file with absolute path without .rb' do
        file_tree %w(one/two/test)

        File.join(root, 'one/two/test').should actually_require(:not_found)
      end

      it 'ignores an absolute not .rb file with absolute path with .rb' do
        file_tree %w(one/two/test)

        File.join(root, 'one/two/test.rb').should actually_require(:not_found)
      end

      it 'returns false when the path is already being required' do
        begin
          first_path = File.join(root, 'first.rb')
          second_path = File.join(root, 'second.rb')
          results = $recurse_require_spec_test = {require_executions: [],
                                                  return_values_in_first: [],
                                                  return_values_in_second: [],
                                                  nb_requires: 0,
                                                  require_method: method(:custom_require_or_reason),
                                                 }

          File.write(first_path, <<-RUBY)
            if $recurse_require_spec_test[:nb_requires] < 5
              $recurse_require_spec_test[:nb_requires] += 1
              $recurse_require_spec_test[:require_executions] << 'first'
              require_method = $recurse_require_spec_test[:require_method]
              $recurse_require_spec_test[:return_values_in_first] << require_method.call(#{second_path.inspect})
            end
          RUBY

          File.write(second_path, <<-RUBY)
            if $recurse_require_spec_test[:nb_requires] < 5
              $recurse_require_spec_test[:nb_requires] += 1
              $recurse_require_spec_test[:require_executions] << 'second'
              require_method = $recurse_require_spec_test[:require_method]
              $recurse_require_spec_test[:return_values_in_second] << require_method.call(#{first_path.inspect})
            end
          RUBY

          ret_val = custom_require_or_reason(first_path)

          ret_val.should == true
          results[:require_executions].should == ['first', 'second']
          results[:return_values_in_first].should == [true]
          results[:return_values_in_second].should == [false]
          results[:nb_requires].should == 2
        ensure
          $recurse_require_spec_test = nil
        end
      end

      it 'keeps symlinks when going through load_path (Ruby < 2.5)' do
        skip if RUBY_VERSION >= '2.5'
        file_tree %w(one/test.rb)
        FileUtils.ln_s from_root('one'), from_root('sym_one')
        add_load_path 'sym_one'

        'test'.should actually_require('one/test.rb', expected_loaded_feature: 'sym_one/test.rb')
      end

      it 'symlinks are removed when going through load_path (Ruby >= 2.5)' do
        skip if RUBY_VERSION < '2.5'
        file_tree %w(one/test.rb)
        FileUtils.ln_s from_root('one'), from_root('sym_one')
        add_load_path 'sym_one'

        'test'.should actually_require('one/test.rb', expected_loaded_feature: 'one/test.rb')
      end

      it 'a ./path keeps symlinks after the current work dir' do
        file_tree %w(pwd:one/
                     one/test.rb
                     one/two/test.rb
                    )
        FileUtils.ln_s from_root('one/two'), from_root('one/sym_two')

        './sym_two/test'.should actually_require('one/two/test.rb', expected_loaded_feature: 'one/sym_two/test.rb')
      end

      it 'a ../path keeps symlinks after the current work dir' do
        file_tree %w(pwd:one/deeper/
                     one/test.rb
                     one/two/test.rb
                    )
        FileUtils.ln_s from_root('one/two'), from_root('one/sym_two')

        '../sym_two/test'.should actually_require('one/two/test.rb', expected_loaded_feature: 'one/sym_two/test.rb')
      end

      # NOTE: This actually happens at OS level (at least on Linux and Mac)
      #       But this verifies that the test system won't fail when the current work dir
      #       contains a symlink.
      it 'a ./path resolves symlinks in the current work dir' do
        file_tree %w(one/test.rb
                     one/two/test.rb
                    )

        FileUtils.ln_s from_root('one'), from_root('sym_one')

        @root = File.join(root, 'sym_one')
        Dir.chdir(@root)

        # expected_loaded_feature will get joined to the @root, which is already on one through a symlink.
        './two/test'.should actually_require('one/two/test.rb', expected_loaded_feature: 'two/test.rb')
      end

      it 'it indicates that .so files are not supported' do
        file_tree %w(one/two/test.so)

        add_load_path 'one'
        'two/test.so'.should actually_require(:file_extension_is_so)
      end

      it 'outputs some diagnostics if DeepCover creates a syntax error', exclude: :JRuby do
        defined?(TrivialGem).should be_nil # Sanity check
        path = Pathname.new(__dir__).join('cli_fixtures/trivial_gem/lib/trivial_gem/version.rb')
        # Fake a rewriting problem:
        allow_any_instance_of(DeepCover::CoveredCode).to receive(:instrument_source)
          .and_return("2 + 2 == 4\nthis is invalid ruby)}]")

        return_value = nil
        expect do
          return_value = custom_require_or_reason(path.to_s)
        end.to output(/version.rb:2:/).to_stderr

        return_value.should == :cover_failed
      end

      describe 'when filtering' do
        let(:calls) { [] }
        let(:requirer) do
          CustomRequirer.new(load_paths: [], loaded_features: [], lookup_paths: ['/']) do |path|
            calls << path
            answer
          end
        end
        before do
          file_tree %w(one/test.rb)
          add_load_path 'one'
        end
        describe 'returns true' do
          let(:answer) { true }
          it 'allows skipping a custom require' do
            custom_require_or_reason('test').should == :skipped
            calls.should == ["#{root}/one/test.rb"]
          end
        end
        describe 'returns false' do
          let(:answer) { false }
          it { custom_require_or_reason('test').should == true }
        end
      end
    end

    describe 'when given a lookup root' do
      let(:lookup_paths) { ["#{root}/other", "#{root}/one/root"] }
      let(:calls) { [] }
      before do
        file_tree %w(pwd:one/root/
                     one/outside.rb
                     one/root/test.rb
                     one/root/sub/other.rb
                     two/also_outside.rb
                    )
        add_load_path 'one'
        add_load_path 'one/root'
        add_load_path 'one/root/sub'
        add_load_path 'two'
      end
      {'relative — from above the root' => 'outside',
       'relative — not related to root' => 'also_outside',
       'absolute - not inside root' => '../outside.rb',
       'absolute - not existing' => './not_existing',
      }.each do |kind, path|
        describe "for a file outside of it (#{kind})" do
          it 'requires fallback' do
            custom_require_or_reason(format(path, root: root)).should == :not_found
          end
        end
      end
      {'relative — from the root' => 'test',
       'relative — from inside the root' => 'other',
       'relative — from above the root' => 'root/sub/other',
       'absolute' => './test',
      }.each do |kind, path|
        describe "for a file inside of it (#{kind})" do
          it { custom_require_or_reason(path).should == true }
        end
      end
    end

    describe '#load' do
      it 'regular path checks current work dir' do
        file_tree %w(    one/test.rb
                         pwd:one/two/
                         one/two/test.rb
                         one/two/three/test.rb
        )

        result = requirer.load('test.rb')
        result.should == true
        $last_test_tree_file_executed.should == 'one/two/test.rb'
        requirer.loaded_features.should == []
      end
    end
  end
end
