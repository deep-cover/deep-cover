# frozen_string_literal: true

module DeepCover
  module Tools::ScanMatchDatas
    # Like String#scan, but return the MatchData object instead
    def scan_match_datas(source, matcher)
      # This has wrong behavior in truffleruby
      # source.to_enum(:scan, matcher).map { Regexp.last_match }
      # This is the fool-proof way of doing it. Maybe some checks for perf should be done
      start_at = 0
      matches = []
      while match = source.match(matcher, start_at)
        matches.push(match)
        start_at = match.end(0)
      end
      matches
    end
  end
end
