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

    def add_load_path(path)
      requirer.load_path << File.absolute_path(path, root)
    end

    def file_tree(tree_entries)
      DeepCover::Tools.file_tree(root, tree_entries)
    end


    # After returning, any traces of having done requires are removed from both ruby and `requirer`
    # Can receive a block to nest tests on multiple requires.
    def compare_require(require_path, expected_executed_file, &block)
      expected_executed_absolute_path = File.absolute_path(expected_executed_file, root) if expected_executed_file.is_a?(String)
      init_loaded_features = requirer.loaded_features.dup

      $last_test_tree_file_executed = nil
      custom_result = requirer.require(require_path)
      custom_executed_file = $last_test_tree_file_executed

      $last_test_tree_file_executed = nil
      begin
        tmp_load_path = $LOAD_PATH.dup
        $LOAD_PATH[0..-1] = requirer.load_path
        tmp_loaded_features = $LOADED_FEATURES.dup
        $LOADED_FEATURES[0..-1] = init_loaded_features
        ruby_result = require(require_path)
      rescue LoadError
        ruby_result = :not_found
      ensure
        ruby_loaded_features_after = $LOADED_FEATURES.dup
        $LOAD_PATH[0..-1] = tmp_load_path
        $LOADED_FEATURES[0..-1] = tmp_loaded_features
      end
      ruby_executed_file = $last_test_tree_file_executed
      $last_test_tree_file_executed = nil

      if expected_executed_file == :not_found
        expected_executed_file = nil
        expected_result = :not_found
      elsif expected_executed_file == false
        expected_executed_file = nil
        expected_result = false
      else
        expected_result = true
      end

      custom_result.should eq(ruby_result).and eq(expected_result)

      custom_executed_file.should eq(ruby_executed_file).and eq(expected_executed_file)

      expected_loaded_features = init_loaded_features + [expected_executed_absolute_path].compact
      requirer.loaded_features.should eq(ruby_loaded_features_after).and eq(expected_loaded_features)
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

        compare_require('./test', 'one/two/test.rb')
      end

      it "a ./path ignores the load_path" do
        file_tree %w(one/two/
                     one/two/test.rb
                     one/two/three/test.rb)

        add_load_path 'one/two'
        compare_require('./test', :not_found)
      end

      it "handles a ../path relatively to current work dir" do
        file_tree %w(pwd:one/two/
                         one/test.rb
                         one/two/test.rb
                         one/two/three/test.rb)

        compare_require('../test', 'one/test.rb')
      end

      it "a ../path ignores the load_path" do
        file_tree %w(one/two/
                     one/two/test.rb
                     one/two/three/test.rb)
        add_load_path 'one/two/three'

        compare_require('../test', :not_found)
      end

      it "a /../ in a path after a name will go to the parent" do
        file_tree %w(one/test.rb
                     one/two/test.rb
                     one/two/three/test.rb)
        add_load_path 'one'

        compare_require('two/../test', 'one/test.rb')
      end

      it "a /./ in a path after a name will be ignored " do
        file_tree %w(one/test.rb
                     one/two/test.rb
                     one/two/three/test.rb)
        add_load_path 'one'

        compare_require('two/./test', 'one/two/test.rb')
      end

      it "Can go to parent of load_path with multiple /../" do
        file_tree %w(one/test.rb
                     one/two/test.rb
                     one/two/three/test.rb)
        add_load_path 'one/two'

        compare_require('three/../../test', 'one/test.rb')
      end

      it "finds files with directories in the required path" do
        file_tree %w(one/test.rb
                     one/two/test.rb
                     one/two/three/test.rb)
        add_load_path 'one'

        compare_require('two/three/test', 'one/two/three/test.rb')
      end

      it "uses the matching file from the the first matching load_path" do
        file_tree %w(one/test.rb
                     one/two/test.rb
                     one/two/three/test.rb)
        add_load_path 'one'
        add_load_path 'one/two'
        add_load_path 'one/two/three'

        compare_require('test', 'one/test.rb')
      end

      # TOMA: Is that a useless test?
      it "doesn't use a wrong file form the matching directly" do
        file_tree %w(one/test.rb
                     one/two/abc.rb
                     one/two/test.rb
                     one/two/zyx.rb
                     one/two/three/test.rb)
        add_load_path 'one/two'

        compare_require('test', 'one/two/test.rb')
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

        compare_require('test', 'one/test.rb')
        compare_require('test', false)
      end

      it "doesn't execute a file that was already required through another load_path" do
        file_tree %w(one/test.rb
                     one/two/test.rb
                     one/two/three/test.rb)
        add_load_path 'one/two'
        compare_require('test', 'one/two/test.rb')

        add_load_path 'one'
        compare_require('two/test', false)
      end

      it "doesn't find from path around the load_path" do
        file_tree %w(one/test.rb
                     one/two/
                     one/two/three/test.rb)
        add_load_path 'one/two'

        compare_require('test', :not_found)
      end

      it "regular path ignores current work dir" do
        file_tree %w(    one/test.rb
                     pwd:one/two/
                         one/two/test.rb
                         one/two/three/test.rb)

        compare_require('test', :not_found)
      end

      it "ignores a not .rb file when path includes .rb" do
        file_tree %w(one/test.rb
                     one/two/test
                     one/two/three/test.rb)
        add_load_path 'one/two'

        compare_require('test', :not_found)
      end

      it "ignores a not .rb file when path is without .rb" do
        file_tree %w(one/test.rb
                     one/two/test
                     one/two/three/test.rb)
        add_load_path 'one/two'

        compare_require('test', :not_found)
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

