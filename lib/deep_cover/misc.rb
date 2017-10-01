module DeepCover
  module Misc
    def self.require_relative_dir(dir_name)
      dir = File.dirname(caller.first.partition(/\.rb:\d/).first)
      Dir["#{dir}/#{dir_name}/*.rb"].sort.each do |file|
        require file
      end
    end

  end
end
