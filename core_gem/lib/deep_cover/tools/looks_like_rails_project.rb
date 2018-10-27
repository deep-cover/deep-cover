# frozen_string_literal: true

module DeepCover
  module Tools::LooksLikeRailsProject
    extend self
    def looks_like_rails_project?(path)
      path = File.expand_path(path)
      %w(app config/application.rb config/environments db/migrate lib).all? do |q_path|
        File.exist?("#{path}/#{q_path}")
      end
    end
  end
end
