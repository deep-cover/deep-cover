module DeepCover
  module Tools::Profiling
    # Simple forwarding to implementation
    def start
      profiler.start
    end

    def stop
      @results = profiler.stop
    end

    def pause
      profiler.pause
    end

    def resume
      profiler.resume
    end

    def report
      profiler.report(@results)
    end

    # Basic utilities using forwarding methods
    def profile(do_start = true)
      return yield unless do_start
      start
      yield
      stop
      report
    end

    def dont_profile
      pause if profiler_loaded?
      yield
    ensure
      resume if profiler_loaded?
    end

    def profiler_loaded?
      !!@profiler
    end

    private
    # Dependency injection
    def profiler
      require 'ruby-prof'
      @profiler = RubyProfProfiler.new
    end

    class RubyProfProfiler < SimpleDelegator
      def initialize
        require 'ruby-prof'
        super(RubyProf)
      end

      def report(results)
        printer = RubyProf::GraphPrinter.new(results)
        printer.print(STDOUT, {})
      end
    end
  end
end
