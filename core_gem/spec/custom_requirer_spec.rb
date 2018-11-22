# frozen_string_literal: true

require_relative 'spec_helper'

module DeepCover
  SO = RbConfig::CONFIG['DLEXT'] # so | bundle | jar | ...
  RSpec.describe CustomRequirer do
    # We specify the glob, because otherwise the generated glob will only match .rb files (/**/*.rb), while we want
    # to also match extensions for the purpose of the tests
    let(:lookup_globs) { ['/**/*'] }
    let(:requirer) { CustomRequirer.new(load_paths: [], loaded_features: []) }
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

    before(:each) do
      lg = lookup_globs
      DeepCover.configure do
        paths(lg)
      end
    end

    after(:each) { DeepCover.reset }

    matcher :actually_execute do |expected_executed_file, **options|
      match do |require_path|
        @result = {}
        @executed_file = {}
        @loaded_features = {}
        @method_name = options[:method] || execute_method_name
        raise 'Need option :method to be :require or :load' unless %w(require load).include?(@method_name.to_s)
        @method_name = @method_name.to_sym

        set_expectations(expected_executed_file, options[:expected_loaded_feature])

        run_ruby(require_path)
        run_custom_requirer(require_path)

        # At the moment, the only case of not_supported is when a .so file is found
        @result[:custom] = :native_extension if @result[:custom] == :not_supported

        %w(result executed_file loaded_features).all? do |value_name|
          values = instance_variable_get("@#{value_name}").values
          values.delete(:skip_this)
          values.all? { |v| v == values[0] }
        end
      end

      failure_message do |require_path|
        [
          "Unexpected effects of `#{@method_name} #{require_path.inspect}`:",
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
        if @method_name == :require && expected_executed_file.is_a?(String)
          expected_loaded_feature ||= expected_executed_file
          @loaded_features[:expected] += [from_root(expected_loaded_feature)]
        end
      end

      # Must be run before run_custom_require
      def run_ruby(require_path)
        $last_test_tree_file_executed = nil
        # Test ruby require
        begin
          tmp_load_path = $LOAD_PATH.dup
          $LOAD_PATH[0..-1] = requirer.load_paths
          tmp_loaded_features = $LOADED_FEATURES.dup
          $LOADED_FEATURES[0..-1] = requirer.loaded_features
          @result[:ruby] = send(@method_name, require_path)
          if RUBY_PLATFORM == 'java'
            if @result[:ruby] == true && !$LOADED_FEATURES.empty? && $LOADED_FEATURES.last.end_with?('.jar')
              # JRuby doesn't seems to fail on an empty/bad jar...
              # So we must manually detect the native_extension here
              @result[:ruby] = :native_extension
              $LOADED_FEATURES.pop
            end
          end
        rescue LoadError => e
          if e.message[/undefined symbol/] || e.message[/symbol not found/]
            @result[:ruby] = :native_extension
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

      def run_custom_requirer(require_path)
        $last_test_tree_file_executed = nil
        @result[:custom] = execute_custom_requirer_or_reason(require_path, method: @method_name)
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

    # Use as a matcher, this is a curried alias for actually_execute
    def actually_require(expected_executed_file, **options)
      actually_execute(expected_executed_file, method: :require, **options)
    end

    # Use as a matcher, this is a curried alias for actually_execute
    def actually_load(expected_executed_file, **options)
      actually_execute(expected_executed_file, method: :load, **options)
    end

    # This cannot be a `let` because we want to be able to change it
    def root
      Pathname.new(@root).realpath.to_s
    end

    def prepend_load_path(path)
      requirer.load_paths.insert(0, from_root(path))
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

    def execute_custom_requirer_or_reason(path, method: execute_method_name)
      requirer.send(method, path) { |reason| reason }
    end

    def custom_require_or_reason(path)
      execute_custom_requirer_or_reason(path, method: :require)
    end

    def with_ruby_globals_of_custom_requirer
      # Test ruby require

      tmp_load_path = $LOAD_PATH.dup
      $LOAD_PATH[0..-1] = requirer.load_paths
      tmp_loaded_features = $LOADED_FEATURES.dup
      $LOADED_FEATURES[0..-1] = requirer.loaded_features
      yield
    ensure
      $LOAD_PATH[0..-1] = tmp_load_path
      $LOADED_FEATURES[0..-1] = tmp_loaded_features
    end

    shared_examples '#load & #require' do |method_name:, default_extension: nil|
      let(:execute_method_name) { method_name }

      define_method :with_extension do |path|
        next path if default_extension.nil?
        next path if path.end_with?(default_extension)
        "#{path}#{default_extension}"
      end

      it 'handles a ./path relatively to current work dir' do
        file_tree %w(pwd:one/two/
                     one/two/test.rb
                     one/two/three/test.rb
                    )

        with_extension('./test').should actually_execute('one/two/test.rb')
      end

      it 'handles a Pathname instance' do
        file_tree %w(pwd:one/two/
                     one/two/test.rb
                     one/two/three/test.rb
                    )

        Pathname(with_extension('./test')).should actually_execute('one/two/test.rb')
      end

      it 'a ./path ignores the load_path' do
        file_tree %w(one/two/test.rb
                     one/two/three/test.rb
                    )

        add_load_path 'one/two'
        with_extension('./test').should actually_execute(:not_found)
      end


      it 'handles a ../path relatively to current work dir' do
        file_tree %w(pwd:one/two/
                     one/test.rb
                     one/two/test.rb
                     one/two/three/test.rb
                    )

        with_extension('../test').should actually_execute('one/test.rb')
      end

      it 'a ../path ignores the load_path' do
        file_tree %w(one/two/test.rb
                     one/two/three/test.rb
                    )
        add_load_path 'one/two/three'

        with_extension('../test').should actually_execute(:not_found)
      end

      it 'a /../ in a path after a name will go to the parent' do
        file_tree %w(one/test.rb
                     one/two/test.rb
                     one/two/three/test.rb
                    )
        add_load_path 'one'

        with_extension('two/../test').should actually_execute('one/test.rb')
      end

      it 'a /./ in a path after a name will be ignored ' do
        file_tree %w(one/test.rb
                     one/two/test.rb
                     one/two/three/test.rb
                    )
        add_load_path 'one'

        with_extension('two/./test').should actually_execute('one/two/test.rb')
      end

      it 'Can go to parent of load_path with multiple /../' do
        file_tree %w(one/test.rb
                     one/two/test.rb
                     one/two/three/test.rb
                    )
        add_load_path 'one/two'

        with_extension('three/../../test').should actually_execute('one/test.rb')
      end

      it 'finds files with directories in the required path' do
        file_tree %w(one/test.rb
                     one/two/test.rb
                     one/two/three/test.rb
                    )
        add_load_path 'one'

        with_extension('two/three/test').should actually_execute('one/two/three/test.rb')
      end

      it 'uses the matching file from the the first matching load_path' do
        file_tree %w(one/test.rb
                     one/two/test.rb
                     one/two/three/test.rb
                    )
        add_load_path 'one'
        add_load_path 'one/two'
        add_load_path 'one/two/three'

        with_extension('test').should actually_execute('one/test.rb')
      end

      it "doesn't use a wrong file form the matching directly" do
        file_tree %w(one/test.rb
                     one/two/abc.rb
                     one/two/test.rb
                     one/two/zyx.rb
                     one/two/three/test.rb
                    )
        add_load_path 'one/two'

        with_extension('test').should actually_execute('one/two/test.rb')
      end

      it "doesn't find from parent or subdir of the load_path" do
        file_tree %w(one/test.rb
                     one/two/three/test.rb
                    )
        add_load_path 'one/two'

        with_extension('test').should actually_execute(:not_found)
      end

      describe 'when given a lookup root' do
        let(:lookup_globs) { ["#{root}/other", "#{root}/one/root"] }
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
        {'relative — from above the root' => ['outside', :not_in_covered_paths],
         'relative — not related to root' => ['also_outside', :not_in_covered_paths],
         'absolute - not inside root' => ['../outside.rb', :not_in_covered_paths],
         'absolute - not existing' => ['./not_existing', :not_found],
        }.each do |kind, (path, result)|
          describe "for a file outside of it (#{kind})" do
            it 'requires fallback' do
              execute_custom_requirer_or_reason(format(with_extension(path), root: root)).should == result
            end
          end
        end
        {'relative — from the root' => 'test',
         'relative — from inside the root' => 'other',
         'relative — from above the root' => 'root/sub/other',
         'absolute' => './test',
        }.each do |kind, path|
          describe "for a file inside of it (#{kind})" do
            it { execute_custom_requirer_or_reason(with_extension(path)).should == true }
          end
        end
      end
    end

    describe '#load' do
      include_examples '#load & #require', method_name: :load, default_extension: '.rb'


      it 'fallbacks to checking relative to current work dir' do
        file_tree %w(one/test.rb)
        Dir.chdir(@root)
        'one/test.rb'.should actually_load('one/test.rb')
      end

      it '$LOAD_PATH has priority over fallback to checking relative to current work dir' do
        file_tree %w(one/test.rb
                     test.rb
                    )
        add_load_path 'one'
        Dir.chdir(@root)
        'test.rb'.should actually_load('one/test.rb')
      end

      it 'ignores a file that would be found with .rb added' do
        file_tree %w(one/test.rb)
        add_load_path 'one'

        'test'.should actually_load(:not_found)
        'test.rb'.should actually_load('one/test.rb')
      end

      it "loads a file that doesn't have a .rb if it matches exactly" do
        file_tree %w(one/test)
        add_load_path 'one'

        'test'.should actually_load('one/test')
        'test.rb'.should actually_load(:not_found)
      end
    end

    describe '#require' do
      include_examples '#load & #require', method_name: :require

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

        from_root('one/two/test').should actually_require('one/two/test.rb')
      end

      it 'accepts an absolute .rb file with absolute path with .rb' do
        file_tree %w(one/two/test.rb)

        from_root('one/two/test.rb').should actually_require('one/two/test.rb')
      end

      it 'ignores an absolute not .rb file with absolute path without .rb' do
        file_tree %w(one/two/test)

        from_root('one/two/test').should actually_require(:not_found)
      end

      it 'ignores an absolute not .rb file with absolute path with .rb' do
        file_tree %w(one/two/test)

        from_root('one/two/test.rb').should actually_require(:not_found)
      end

      {custom_require_or_reason: 'custom_requirer', require: 'ruby require'}.each do |method_name, context_name|
        it "(#{context_name}) returns false when the path is already being required" do
          begin
            first_path = from_root('first.rb')
            second_path = from_root('second.rb')

            results = $recurse_require_spec_test = {require_executions: [],
                                                    return_values_in_first: [],
                                                    return_values_in_second: [],
                                                    nb_requires: 0,
                                                    require_method: method(method_name),
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

            ret_val = send(method_name, first_path)

            ret_val.should == true
            results[:require_executions].should == ['first', 'second']
            results[:return_values_in_first].should == [true]
            results[:return_values_in_second].should == [false]
            results[:nb_requires].should == 2
          ensure
            $recurse_require_spec_test = nil
          end
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

        @root = from_root('sym_one')
        Dir.chdir(@root)

        # expected_loaded_feature will get joined to the @root, which is already on one through a symlink.
        './two/test'.should actually_require('one/two/test.rb', expected_loaded_feature: 'two/test.rb')
      end

      it 'indicates that .so files are not supported when the .so is specified and the file is found' do
        file_tree %W(one/two/test.#{SO})

        add_load_path 'one'
        "two/test.#{SO}".should actually_require(:native_extension)
      end

      it 'indicates that .so files are not supported when the .so is not specified and the file is found' do
        file_tree %W(one/two/test.#{SO})

        add_load_path 'one'
        'two/test'.should actually_require(:native_extension)
      end

      it 'indicates not_found for missing .so files' do
        add_load_path 'one'
        "two/test#{SO}".should actually_require(:not_found)
      end

      it 'prefers .rb files over .so files if in same LOAD_PATH' do
        file_tree %W(one/two/test.rb
                     one/two/test.#{SO}
                    )

        add_load_path 'one'
        'two/test'.should actually_require('one/two/test.rb')
        # Verify that the .so could be found
        "two/test.#{SO}".should actually_require(:native_extension)
      end

      it 'prefers .rb files of a later LOAD_PATH over previous .so files' do
        file_tree %W(one/two/test.#{SO}
                     then/two/test.rb
                     )

        add_load_path 'one'
        add_load_path 'then'

        'two/test'.should actually_require('then/two/test.rb')
        # Verify that the .so could be found
        "two/test.#{SO}".should actually_require(:native_extension)
      end

      it 'prefers .rb files of a previous LOAD_PATH over .so file that follows' do
        file_tree %W(one/two/test.rb
                     then/two/test.#{SO}
                     )

        add_load_path 'one'
        add_load_path 'then'
        'two/test'.should actually_require('one/two/test.rb')
        # Verify that the .so could be found
        "two/test.#{SO}".should actually_require(:native_extension)
      end

      # a built-in feature is basically just a single file-name (not an absolute path)
      it 'handles ruby built-ins LOADED_FEATURES' do
        requirer.loaded_features << 'somewhere.rb'
        'somewhere'.should actually_require(false) if RUBY_PLATFORM != 'java'
        'somewhere.rb'.should actually_require(false)
      end

      it 'ruby built-ins LOADED_FEATURES hide other matching file from the load_path' do
        file_tree %w(one/somewhere.rb
                     )

        add_load_path 'one'
        requirer.loaded_features << 'somewhere.rb'
        'somewhere'.should actually_require(false) if RUBY_PLATFORM != 'java'
        'somewhere.rb'.should actually_require(false)
      end

      it "doesn't require if a LOAD_PATH + required path already matches a LOADED_FEATURES" do
        file_tree %w(one/two/test.rb
                     then/two/test.rb
                     again/two/test.rb
                     )

        add_load_path 'then'
        'two/test'.should actually_require('then/two/test.rb')
        prepend_load_path 'one'
        add_load_path 'again'
        'two/test'.should actually_require(false)
      end

      {custom_require_or_reason: 'custom_requirer', require: 'ruby require'}.each do |method_name, context_name|
        it "(#{context_name}) still requires if a later LOAD_PATH + required path is already being loaded" do
          file_tree %w(one/
                       second/
                      )
          add_load_path 'one'

          begin
            first_path = from_root('one/file.rb')
            second_path = from_root('second/file.rb')

            if method_name == :custom_require_or_reason
              load_paths = requirer.load_paths
            elsif method_name == :require
              load_paths = $LOAD_PATH
            end

            results = $recurse_require_spec_test = {require_executions: [],
                                                    return_values_in_first: [],
                                                    require_method: method(method_name),
                                                    load_paths: load_paths,
                                                   }

            File.write(first_path, <<-RUBY)
              $recurse_require_spec_test[:require_executions] << 'first'
              $recurse_require_spec_test[:load_paths].insert(0, #{from_root('second').inspect})
              require_method = $recurse_require_spec_test[:require_method]
              $recurse_require_spec_test[:return_values_in_first] << require_method.call('file')
            RUBY

            File.write(second_path, <<-RUBY)
              $recurse_require_spec_test[:require_executions] << 'second'
            RUBY

            ret_val = with_ruby_globals_of_custom_requirer do
              send(method_name, 'file')
            end

            ret_val.should == true
            results[:require_executions].should == ['first', 'second']
            results[:return_values_in_first].should == [true]
          ensure
            $recurse_require_spec_test = nil
          end
        end
      end

      it 'outputs some diagnostics if DeepCover creates a syntax error', exclude: :JRuby do
        defined?(TrivialGem).should be_nil # Sanity check
        path = Pathname.new(__dir__).join('code_fixtures/trivial_gem/lib/trivial_gem/version.rb')
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
          CustomRequirer.new(load_paths: [], loaded_features: []) do |path|
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
