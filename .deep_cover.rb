# frozen_string_literal: true

# This file is executed only when deep_cover is covering itself.

DeepCover.configure do
  tracker_global '$_dcg'
  ignore_uncovered :warn, :raise, :default_argument
end
