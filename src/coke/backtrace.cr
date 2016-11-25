module Coke

  module Backtrace

    SUPPRESSED_PATHS_RE = ""

    SUPPRESS_PATTERN = %r((\A(#{SUPPRESSED_PATHS_RE})|bin/coke:\d+))i

    def self.collapse(backtrace)
      pattern = Coke.application.options.suppress_backtrace_pattern ||
                SUPPRESS_PATTERN
      backtrace.reject { |elem| elem =~ pattern }
    end
  end

end
