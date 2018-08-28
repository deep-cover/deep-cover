# frozen_string_literal: true

# Basic constants without any dependencies are here
module DeepCover
  DEFAULTS = {
               ignore_uncovered: [].freeze,
               paths: %w[./app ./lib].freeze,
               allow_partial: false,
               tracker_global: '$_cov',
               reporter: :html,
               output: './coverage',
             }.freeze

  CLI_DEFAULTS = {
                   command: 'bundle exec rake',
                   bundle: true,
                   process: true,
                   open: false,
                 }.freeze

  OPTIONALLY_COVERED = %i[case_implicit_else default_argument raise trivial_if warn]

  REQUIRABLE_EXTENSIONS = {
                            '.rb' => :ruby,
                            ".#{RbConfig::CONFIG['DLEXT']}" => :native_extension,
                          }
  unless (RbConfig::CONFIG['DLEXT2'] || '').empty?
    REQUIRABLE_EXTENSIONS[".#{RbConfig::CONFIG['DLEXT2']}"] = :native_extension
  end
  REQUIRABLE_EXTENSIONS.freeze
  REQUIRABLE_EXTENSION_KEYS = REQUIRABLE_EXTENSIONS.keys.freeze
end
