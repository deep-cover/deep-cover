module DeepCover
  module Tools::Camelize
    # Poor man's camelize. 'an_example' => 'AnExample'
    def camelize(string)
      string.to_s.gsub(/([a-z\d]*)[_?!]?/){ $1.capitalize }
    end
  end
end
