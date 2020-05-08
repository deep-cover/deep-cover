# frozen_string_literal: true

top_level_module = Thread.current['_deep_cover_top_level_module'] || Object

module top_level_module::DeepCover # rubocop:disable Naming/ClassAndModuleCamelCase
  VERSION = '0.8.1'
end
