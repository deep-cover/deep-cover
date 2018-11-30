# frozen_string_literal: true

require_relative 'spec_helper'

RSpec.describe DeepCover do
  describe 'cover' do
    after { DeepCover.reset }
    it 'temporarily overrides (or not in MRI 2.3+) `require`, `require_relative` and `autoload`' do
      methods = %i[require require_relative]
      methods << :autoload unless RUBY_PLATFORM == 'java'
      original = methods.map { |m| method(m).source_location }
      2.times do
        sources = nil
        DeepCover.cover do
          sources = methods.map { |m| method(m).source_location }
        end
        sources.zip(original).each do |now, before|
          if RUBY_VERSION >= '2.3.0' && DeepCover.on_mri?
            # We use load_iseq in 2.3+, so no override in that case
            now.should == before
          else
            now.should_not == before
          end
        end
        methods.map { |m| method(m).source_location }.should == original
      end
    end

    it "doesn't choke on a file with encoding snafus" do
      $bad_encoding_test = nil
      DeepCover.cover paths: '/' do
        expect do
          Tempfile.open(['bad_encoding_test', '.rb']) do |f|
            f.write('a_string = "\\xE9"; $bad_encoding_test = :success')
            f.close
            require(f.path).should == true
          end
        end.to output(/Can't cover .*bad_encoding_test.*\.rb because of incompatible encoding/).to_stderr
      end
      $bad_encoding_test.should == :success
    end
  end
end
