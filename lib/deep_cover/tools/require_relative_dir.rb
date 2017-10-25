module DeepCover
  module Tools::RequireRelativeDir
    def require_relative_dir(dir_name, except: [])
      dir = File.dirname(caller.first.partition(/\.rb:\d/).first)
      Dir["#{dir}/#{dir_name}/*.rb"].sort.each do |file|
        require file unless except.include? File.basename(file, '.rb')
      end
    end
  end
end
