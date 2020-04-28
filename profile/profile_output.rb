# Run with:
#   bundle exec ruby profile/profile_output.rb

require 'deep-cover'

module DeepCover
  configure do
    paths 'profile/fixtures'
  end
  cover do
    require_relative 'fixtures/converter'
  end
  Tools.profile do
    coverage.report(reporter: :html)
  end
end
