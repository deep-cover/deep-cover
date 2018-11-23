# frozen_string_literal: true


# Putting that in the run_successfully matcher basically works|
#
# output, errors, exit_code = Bundler.with_clean_env do
#   DeepCover::Tools.jruby_fast_call(File.absolute_path('simple/simple.rb', @from_dir), ['no_deep_cover'], chdir: @from_dir)
# end
#
# @output = output.chomp
# @errors = errors.chomp
# @exit_code = exit_code


module DeepCover
  module Tools::JrubyFastCall
    def jruby_fast_call(ruby_file, args, chdir: nil)
      embed = org.jruby.embed
      # The false is so that nothing gets shared between this Ruby and the executed script
      container = embed.ScriptingContainer.new(embed.LocalContextScope::THREADSAFE, embed.LocalVariableBehavior::PERSISTENT, false)

      error = java.io.StringWriter.new
      container.set_error(error)
      output = java.io.StringWriter.new
      container.set_output(output)

      # For whatever reason, this HAS to be after the setError/setOutput
      container.put 'ARGV', args

      #container.setInput something

      execute_lambda = -> { container.run_scriptlet(embed.PathType::ABSOLUTE, ruby_file) }
      if chdir
        Dir.chdir(chdir) do
          execute_lambda.call
        end
      else
        execute_lambda.call
      end

      # Super hackish way of getting the exit_code.
      # This only returns the exit_code as it is before at_exit are run, so if it gets changed, we will have the wrong one
      # This also doesn't handle calls to #exit!
      exit_code = container.run_scriptlet(<<-RUBY)
        if $!.nil? || $!.is_a?(SystemExit) && $!.success?
          0
        else
          $!.is_a?(SystemExit) ? $!.status : 1
        end
      RUBY

      # This is when the #at_exit are run
      container.terminate

      return output.to_string, error.to_string, exit_code
    end
  end
end
