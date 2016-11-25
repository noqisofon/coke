module Coke

  class OptionStub
    property    thread_pool_size           : Int32
    property    cokelib                    : Array(String)
    property    trace_output               : IO::FileDescriptor
    property    backtrace                  : Bool
    property    suppress_backtrace_pattern : Regex?
    property    ignore_system              : Bool
    property    load_system                : Bool
    property    nosearch                   : Bool

    def initialize(@thread_pool_size           = 0,
                   @cokelib                    = [] of String,
                   @trace_output               = STDOUT,
                   @backtrace                  = true,
                   @suppress_backtrace_pattern = nil,
                   @load_system                = false,
                   @ignore_system              = false,
                   @nosearch                   = false)
    end
  end
  
end
