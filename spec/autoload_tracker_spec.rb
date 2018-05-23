# frozen_string_literal: true

require 'spec_helper'

module DeepCover
  RSpec.describe AutoloadTracker do
    let(:tracker) { AutoloadTracker.new }
    let(:modules) { [Module.new, Module.new] }
    let(:autoload_calls_modules) { [] }
    let(:autoload_calls_names) { [] }
    let(:autoload_calls_paths) { [] }

    let(:autoload_block) do
      ->(mod, name, path) do
        autoload_calls_modules << mod
        autoload_calls_names << name
        autoload_calls_paths << path
      end
    end

    context 'setup_interceptor_for' do
      it "reuses an interceptor for same path if it wasn't required yet" do
        modules.each do |mod|
          tracker.send(:setup_interceptor_for, mod, :A, 'hello')
        end

        tracker.interceptor_files_by_path.keys.should == ['hello']
        tracker.interceptor_files_by_path['hello'].size.should == 1
      end

      it "doesn't reuse an interceptor for same path if it was required" do
        path = tracker.send(:setup_interceptor_for, modules[0], :A, 'hello')
        $LOADED_FEATURES << path
        tracker.send(:setup_interceptor_for, modules[1], :A, 'hello')

        tracker.interceptor_files_by_path.keys.should == ['hello']
        tracker.interceptor_files_by_path['hello'].size.should == 2
      end
    end

    context 'initialize_autoloaded_paths' do
      def do_initialize_autoloaded_path
        tracker.initialize_autoloaded_paths(modules, &autoload_block)
      end

      it 'does nothing with modules that have no autoload' do
        do_initialize_autoloaded_path

        tracker.autoloads_by_basename.should be_empty
        tracker.interceptor_files_by_path.should be_empty
        autoload_calls_modules.should be_empty
        autoload_calls_names.should be_empty
        autoload_calls_paths.should be_empty
      end

      it 'changes the autoload of modules that have autoload' do
        modules.first.autoload :A, 'hello'

        do_initialize_autoloaded_path

        tracker.autoloads_by_basename.keys.should == ['hello']
        tracker.autoloads_by_basename['hello'].size.should == 1
        tracker.interceptor_files_by_path.size.should == 1
        autoload_calls_modules.should == [modules.first]
        autoload_calls_names.should == [:A]
        autoload_calls_paths.size.should == 1
        autoload_calls_paths.first.should match(%r[.*/hello.*\.rb])
      end

      it 'ignores frozen modules' do
        modules.first.autoload :A, 'hello'
        modules.first.freeze
        expect do
          do_initialize_autoloaded_path
        end.to output(%r[There is an autoload on a frozen module/class]).to_stderr
        AutoloadTracker.warned_for_frozen_module = false

        tracker.autoloads_by_basename.should be_empty
        tracker.interceptor_files_by_path.should be_empty
        autoload_calls_modules.should be_empty
        autoload_calls_names.should be_empty
        autoload_calls_paths.should be_empty
      end

      it 'whines for frozen modules only once' do
        modules.first.autoload :A, 'hello'
        modules.first.freeze
        expect do
          do_initialize_autoloaded_path
        end.to output(%r[There is an autoload on a frozen module/class]).to_stderr

        expect do
          do_initialize_autoloaded_path
        end.to_not output(%r[There is an autoload on a frozen module/class]).to_stderr
        AutoloadTracker.warned_for_frozen_module = false
      end
    end

    context 'remove_interceptors' do
      it 'gets rid of the interceptor for the existing autoloads' do
        interceptor_path = tracker.send(:setup_interceptor_for, modules.first, :A, 'hello')
        modules.first.autoload :A, interceptor_path

        tracker.remove_interceptors(&autoload_block)

        autoload_calls_modules.should == [modules.first]
        autoload_calls_names.should == [:A]
        autoload_calls_paths.size.should == 1
        autoload_calls_paths.first.should == 'hello'
      end

      it 'ignores frozen modules' do
        interceptor_path = tracker.send(:setup_interceptor_for, modules.first, :A, 'hello')
        modules.first.autoload :A, interceptor_path
        modules.first.freeze

        expect do
          tracker.remove_interceptors(&autoload_block)
        end.to output(%r[There is an autoload on a frozen module/class]).to_stderr
        AutoloadTracker.warned_for_frozen_module = false

        autoload_calls_modules.should be_empty
        autoload_calls_names.should be_empty
        autoload_calls_paths.should be_empty
      end
    end
  end
end
