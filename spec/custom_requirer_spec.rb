require "spec_helper"

module DeepCover
  RSpec.describe CustomRequirer do
    let(:requirer) { CustomRequirer.new([], []) }
    let(:root) { @root }
    before(:each) { $last_test_tree_file_executed = nil }
    around(:each) do |ex|
      begin
        dir = Dir.mktmpdir("deep_cover_test")
        # Ensure presence of a separator at the end of the string
        @root = File.join(dir, '')

        current_pwd = Dir.pwd
        ex.run
      ensure
        Dir.chdir(current_pwd)
        FileUtils.remove_entry @root
      end
    end

    matcher :actually_require do |expected_executed_file|
      match do |require_path|
        @result = {}
        @executed_file = {}
        @loaded_features = {}

        set_expectations(expected_executed_file)

        run_ruby_require(require_path)
        run_custom_require(require_path)

        %w(result executed_file loaded_features).all? do |value_name|
          values = instance_variable_get("@#{value_name}").values
          values.all?{|v| v == values[0] }
        end
      end

      failure_message do |require_path|
        output = "Unexpected effects of `require #{require_path.inspect}`:\n"
        output << "Return value:\n"
        output << build_output(@result)
        output << "\n\nExecuted file:\n"
        output << build_output(@executed_file)
        output << "\n\nLoaded features:\n"
        output << build_output(@loaded_features)
        output
      end

      def set_expectations(expected_executed_file)
        case expected_executed_file
        when :not_found
          @executed_file[:expected] = nil
          @result[:expected] = :not_found
        when false
          @executed_file[:expected] = nil
          @result[:expected] = false
        else
          @executed_file[:expected] = expected_executed_file
          @result[:expected] = true
        end
        @loaded_features[:expected] = requirer.loaded_features.dup
        @loaded_features[:expected] += [from_root(expected_executed_file)] if expected_executed_file.is_a?(String)
      end

      # Must be run before run_custom_require
      def run_ruby_require(require_path)
        $last_test_tree_file_executed = nil
        # Test ruby require
        begin
          tmp_load_path = $LOAD_PATH.dup
          $LOAD_PATH[0..-1] = requirer.load_path
          tmp_loaded_features = $LOADED_FEATURES.dup
          $LOADED_FEATURES[0..-1] = requirer.loaded_features
          @result[:ruby] = require(require_path)
        rescue LoadError
          @result[:ruby] = :not_found
        ensure
          @loaded_features[:ruby] = $LOADED_FEATURES.dup
          $LOAD_PATH[0..-1] = tmp_load_path
          $LOADED_FEATURES[0..-1] = tmp_loaded_features
        end
        @executed_file[:ruby] = $last_test_tree_file_executed
      end

      def run_custom_require(require_path)
        $last_test_tree_file_executed = nil
        @result[:custom] = requirer.require(require_path)
        @loaded_features[:custom] = requirer.loaded_features.dup
        @executed_file[:custom] = $last_test_tree_file_executed
      end

      def build_output(data_hash)
        keys = [:expected, :ruby, :custom]
        max_ley_length = keys.map(&:size).max
        keys.map do |key|
          indent = " " * (max_ley_length - key.size)
          "  #{key}:#{indent} #{data_hash[key].inspect}"
        end.join("\n")
      end
    end

    def add_load_path(path)
      requirer.load_path << from_root(path)
    end

    def file_tree(tree_entries)
      DeepCover::Tools.file_tree(root, tree_entries)
    end

    def from_root(path)
      File.absolute_path(path, root)
    end

    describe "#require" do
      # TOMA: Pretty much all of those case could be repeated as-is, except for adding a .rb to the require's path.
      #       A lot of these tests could be make for #load also, minus the loaded_features check. What do you think?
      #       In the case of #load, the tests could again be repeated as it (with/without .rb), except now, the without
      #           .rb should just always fail unless a file matches it.
      #       In every test, I have a few extra directories/files, is that dumb?
      #
      #
      it "handles a ./path relatively to current work dir" do
        file_tree %w(pwd:one/two/
                         one/two/test.rb
                         one/two/three/test.rb)

        './test'.should actually_require('one/two/test.rb')
      end

      it "a ./path ignores the load_path" do
        file_tree %w(one/two/test.rb
                     one/two/three/test.rb)

        add_load_path 'one/two'
        './test'.should actually_require(:not_found)
      end

      it "handles a ../path relatively to current work dir" do
        file_tree %w(pwd:one/two/
                         one/test.rb
                         one/two/test.rb
                         one/two/three/test.rb)

        '../test'.should actually_require('one/test.rb')
      end

      it "a ../path ignores the load_path" do
        file_tree %w(one/two/test.rb
                     one/two/three/test.rb)
        add_load_path 'one/two/three'

        '../test'.should actually_require(:not_found)
      end

      it "a /../ in a path after a name will go to the parent" do
        file_tree %w(one/test.rb
                     one/two/test.rb
                     one/two/three/test.rb)
        add_load_path 'one'

        'two/../test'.should actually_require('one/test.rb')
      end

      it "a /./ in a path after a name will be ignored " do
        file_tree %w(one/test.rb
                     one/two/test.rb
                     one/two/three/test.rb)
        add_load_path 'one'

        'two/./test'.should actually_require('one/two/test.rb')
      end

      it "Can go to parent of load_path with multiple /../" do
        file_tree %w(one/test.rb
                     one/two/test.rb
                     one/two/three/test.rb)
        add_load_path 'one/two'

        'three/../../test'.should actually_require('one/test.rb')
      end

      it "finds files with directories in the required path" do
        file_tree %w(one/test.rb
                     one/two/test.rb
                     one/two/three/test.rb)
        add_load_path 'one'

        'two/three/test'.should actually_require('one/two/three/test.rb')
      end

      it "uses the matching file from the the first matching load_path" do
        file_tree %w(one/test.rb
                     one/two/test.rb
                     one/two/three/test.rb)
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
                     one/two/three/test.rb)
        add_load_path 'one/two'

        'test'.should actually_require('one/two/test.rb')
      end

      # TOMA: Should this be split into multiple test?
      #       One checking with only one matching
      #       Then one with multiple matching files to check that it doesn't fallback?
      #       I always wonder in that situation, it feels like some tests should basically
      #       only run if another test passed, as otherwise, they overlap.
      it "doesn't execute a file that was already required" do
        file_tree %w(one/test.rb
                     one/two/test.rb
                     one/two/three/test.rb)
        add_load_path 'one'
        add_load_path 'one/two'
        add_load_path 'one/two/three'

        'test'.should actually_require('one/test.rb')
        'test'.should actually_require(false)
      end

      it "doesn't execute a file that was already required through another load_path" do
        file_tree %w(one/test.rb
                     one/two/test.rb
                     one/two/three/test.rb)
        add_load_path 'one/two'
        'test'.should actually_require('one/two/test.rb')

        add_load_path 'one'
        'two/test'.should actually_require(false)
      end

      it "doesn't find from parent or subdir of the load_path" do
        file_tree %w(one/test.rb
                     one/two/three/test.rb)
        add_load_path 'one/two'

        'test'.should actually_require(:not_found)
      end

      it "regular path ignores current work dir" do
        file_tree %w(    one/test.rb
                     pwd:one/two/
                         one/two/test.rb
                         one/two/three/test.rb)

        'test'.should actually_require(:not_found)
      end

      it "ignores a not .rb file when path includes .rb" do
        file_tree %w(one/test.rb
                     one/two/test
                     one/two/three/test.rb)
        add_load_path 'one/two'

        'test'.should actually_require(:not_found)
      end

      it "ignores a not .rb file when path is without .rb" do
        file_tree %w(one/test.rb
                     one/two/test
                     one/two/three/test.rb)
        add_load_path 'one/two'

        'test'.should actually_require(:not_found)
      end
    end


    describe "#load" do
      it "regular path checks current work dir" do
        file_tree %w(    one/test.rb
                     pwd:one/two/
                         one/two/test.rb
                         one/two/three/test.rb)

        result = requirer.load('test.rb')
        result.should == true
        $last_test_tree_file_executed.should == 'one/two/test.rb'
        requirer.loaded_features.should == []
      end
    end
  end
end

