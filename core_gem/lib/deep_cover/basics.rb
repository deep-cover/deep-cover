# frozen_string_literal: true

# Basic constants without any dependencies are here
module DeepCover
  OPTIONALLY_COVERED = %i[case_implicit_else default_argument raise trivial_if warn]

  FILTER_NAME = Hash.new { |h, k| h[k] = :"ignore_#{k}" }

  ignore_defaults = OPTIONALLY_COVERED.to_h { |opt| [FILTER_NAME[opt], false] }

  DEFAULTS = {
               paths: [:auto_detect].freeze,
               exclude_paths: [].freeze,
               allow_partial: false,
               tracker_global: '$_cov',
               reporter: :html,
               output: './coverage',
               cache_directory: './deep_cover',
               **ignore_defaults,
             }.freeze

  CLI_DEFAULTS = {
                   command: %w(bundle exec rake),
                   process: true,
                   open: false,
                 }.freeze

  REQUIRABLE_EXTENSIONS = {
                            '.rb' => :ruby,
                            ".#{RbConfig::CONFIG['DLEXT']}" => :native_extension,
                          }
  unless (RbConfig::CONFIG['DLEXT2'] || '').empty?
    REQUIRABLE_EXTENSIONS[".#{RbConfig::CONFIG['DLEXT2']}"] = :native_extension
  end
  REQUIRABLE_EXTENSIONS.freeze
  REQUIRABLE_EXTENSION_KEYS = REQUIRABLE_EXTENSIONS.keys.freeze

  CORE_GEM_LIB_DIRECTORY = File.expand_path(__dir__ + '/..')
end
