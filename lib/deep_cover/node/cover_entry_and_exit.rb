module DeepCover
  module Node::CoverEntryAndExit
    include Node::CoverEntry

    def suffix
      "#{super}.tap{$_cov[#{context.nb}][#{nb*2+1}]+=1}"
    end

    def ran_exit?
      exit_runs > 0
    end

    def exit_runs
      @nb ? context.cover.fetch(nb*2+1) : 0
    end

    def changed_control_flow?
      !ran_exit? || super
    end
  end
end
