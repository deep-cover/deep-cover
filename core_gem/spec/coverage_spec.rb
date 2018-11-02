# frozen_string_literal: true

require_relative 'spec_helper'

module DeepCover
  RSpec.describe Coverage do
    # We specify the glob, because otherwise the generated glob will only match .rb files (/**/*.rb), while we want
    # to also match extensions for the purpose of the tests
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

    let(:lookup_globs) { [root] }
    let(:coverage) { Coverage.new }
    before(:each) do
      lg = lookup_globs
      DeepCover.configure do
        paths(lg)
      end
    end

    after(:each) { DeepCover.reset }

    def root
      Pathname.new(@root).realpath.to_s
    end

    def file_tree(tree_entries)
      Specs.file_tree(root, tree_entries)
    end

    context 'add_missing_covered_codes' do
      it 'works' do
        file_tree %w(one.rb
                     one/two/three/test.rb
                    )

        coverage.add_missing_covered_codes
        coverage.covered_codes.size.should == 2
      end

      it 'keeps existing covered_codes' do
        file_tree %w(one.rb
                     one/two/three/test.rb
                    )

        covered_code = coverage.covered_code("#{root}/one.rb")
        coverage.covered_codes.size.should == 1
        coverage.add_missing_covered_codes
        coverage.covered_codes.size.should == 2
        coverage.covered_code("#{root}/one.rb").object_id.should == covered_code.object_id
      end
    end
  end
end
