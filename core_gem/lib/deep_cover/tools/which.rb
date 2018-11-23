# frozen_string_literal: true

module DeepCover
  module Tools::Which
    def which(binary)
      ENV["PATH"].split(File::PATH_SEPARATOR).find {|p| File.exists?( File.join( p, binary ) ) }
    end
  end
end
