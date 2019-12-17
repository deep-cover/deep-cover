# frozen_string_literal: true

module DeepCover
  class CLI
    # Thor comes with a built-in help command. When displaying full help, it calls the class' help
    # We override it to make it more to our taste.

    # Copied from Thor's default one, then customized
    desc 'help [COMMAND]', 'Describe all available commands or one specific command', for: :help
    def self.help(shell, subcommand = false)
      list = printable_commands(true, subcommand)
      Thor::Util.thor_classes_in(self).each do |klass|
        list += klass.printable_commands(false)
      end
      list.sort! { |a, b| a[0] <=> b[0] }

      main_commands, list = Tools.extract_commands_for_help(list, :exec, :clone)

      shell.say 'Main commands:'
      shell.print_table(main_commands, indent: 2, truncate: true)

      lower_level_commands, list = Tools.extract_commands_for_help(list, :gather, :report, :clear, :merge)
      shell.say
      shell.say 'Lower-level commands:'
      shell.print_table(lower_level_commands, indent: 2, truncate: true)

      shell.say
      shell.say 'Misc commands:'
      shell.print_table(list, indent: 2, truncate: true)

      shell.say
      print_options(shell, class_options.values, 'Global')
      shell.say 'Use `deep-cover help CMD` for all options accepted by CMD.'
    end
  end
end
