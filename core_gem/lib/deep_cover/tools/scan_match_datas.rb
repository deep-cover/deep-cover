# frozen_string_literal: true

module DeepCover
  module Tools::ScanMatchDatas
    # Like String#scan, but return the MatchData object instead
    def scan_match_datas(source, matcher)
      source.to_enum(:scan, matcher).map { Regexp.last_match }
    end
  end
end
