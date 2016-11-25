require "option_parser"

require "./backtrace"
require "./file_list"
require "./loader"
require "./option_stub"
require "./task"
require "./task_manager"
require "./trace_output"

module Coke

  class Application
    include TaskManager
    include TraceOutput

    getter   name
    getter   original_dir
    getter   cokefile
    property terminal_columns
    getter   top_level_tasks
    setter   tty_output

    DEFAULT_COKEFILES = [
      "cokefile",
      "Cokefile",
      "cokefile.cr",
      "Cokefile.cr"
    ]

    def initialize()
      super

      @name             = "coke"
      @cokefile         = nil
      @cokefiles        = DEFAULT_COKEFILES.dup
      @pending_imports  = [] of String
      @imported         = [] of String
      @loaders          = {} of String => Coke::Loader
      @default_loader   = Coke::DefaultLoader.new
      @original_dir     = Dir.current
      @top_level_dir    = [] of String

      add_loader "cr", Coke::DefaultLoader.new
      add_loader "cf", Coke::DefaultLoader.new
      add_loader "coke", Coke::DefaultLoader.new

      @tty_output       = STDOUT.tty?
      @terminal_columns = ENV["COKE_COLUMNS"].to_i
    end

    def run
      standard_exception_handling do
        init
        load_cokefile
        top_level
      end
    end

    def init(app_name = "coke")
      standard_exception_handling do
        @name = app_name
        args  = handle_options
        collect_command_line_tasks args
      end
    end

    def load_cokefile
      standard_exception_handling do
        raw_load_cokefile
      end
    end

    def top_level
      run_with_threads do
        if options.show_tasks 
          display_tasks_and_comments
        elsif options.show_prereqs
          display_prerequisites
        else
          top_level_tasks { |task_name| invoke_tasks task_name }
        end
      end
    end

    def run_with_threads
      thread_pool.gather_history if options.job_stats == :history

      yield

      thread_pool.join
      if options.job_stats then
        stats = thread_pool.statistics
        puts "Maximum active threads: #{stats[:max_active_threads]} + main"
        puts "Total threads in play:  #{stats[:total_threads_in_play]} + main"
      end
      ThreadHistoryDisplay.new( thread_pool.history ).show if
        options.job_stats == :history
    end

    def add_loader(ext, loader)
      ext = ".#{ext}" unless ext =~ /^\./

      @loaders[ext] = loader
    end

    def options
      @options
    end

    def thread_pool
      @thread_pool
    end

    def default_task_name
      "default"
    end

    def system_dir
      @system_dir
    end

    def trace(*strings)
      options.trace_output ||= STDERR
      trace_on options.trace_output, *strings
    end

    def have_cokefile
      @cokefiles.each do |filename|
        if File.exists? filename
          others = FileList.glob filename#, File::FNM_CASEFOLD

          return others.size == 1 ? others.first : filename
        elsif filename == ""
          return filename
        end
      end

      nil
    end

    def tty_output?
      @tty_output
    end

    # internal ---------------------------------------------------------------

    protected def invoke_tasks(task_name)
      name, args = parse_task_name( task_name )

      task = self[name]
      task.invoke( *args )
    end

    protected def parse_task_name(task_name)
      matach_data = /^([^\[]+])(?:\[(.*)\])$/.match( task_name.to_s )

      name           = matach_data[1]
      remaining_args = matach_data[2]

      return { task_name, [] of String } unless name
      return { name     , [] of String } if     remaining_args.empty?

      args = [] of String

      loop do
        match_data = /((?:[^\\,]|\\.)*?)\s*(?:,\s*(.*))?$/.match( remaining_args )

        remaining_args = match_data[2]
        args << match_data[1].gsub( /\\(.)/, "\\1" )
        
        break if remaining_args
      end

      return { name, args }
    end

    protected def standard_exception_handling
      yield
    # rescue SystemExit
    #   raise
    rescue err : OptionParser::InvalidOption
      STDERR.puts err.message
      exit 0
    rescue err : Exception
      display_error_message err
      exit_because_of_exception err
    end

    protected def exit_because_of_exception(err)
      exit 0
    end

    protected def display_error_message(err)
      trace "#{name} aborted!"
      display_exception_details err
      trace "Tasks: #{err.cause}" if has_chain? err
      trace "(See full trace by running task with --trace)" unless
        options.backtrace
    end

    protected def display_exception_details(err)
      return if err.nil?
      #seen = Fiber.current[:coke_display_exception_details_seen] ||= [] of Exception
      seen = [] of Exception
      return if seen.includes? err
      seen << err

      display_exception_message_details err
      display_exception_backtrace err
      display_exception_details err.cause if has_cause? err
    end

    protected def has_cause?(err)
      err.responds_to? :cause && err.cause
    end

    protected def display_exception_message_details(err)
      # if err.instance_of? RuntimeError then
      #   trace err.message
      # else
      trace "#{err.class.name}: #{err.message}"
      # end
    end

    protected def display_exception_backtrace(err)
      if options.backtrace 
        trace err.backtrace.join "\n"
      else
        trace Backtrace.collapse( err.backtrace ).join "\n"
      end
    end

    protected def deprecate(old_usage, new_usage, call_size)
      STDERR.puts "WARNING: '#{old_usage}' is deprecated.  Please use '#{new_usage}' instead.\n    at #{call_site}" unless options.ignore_deprecate
    end

    private def has_chain?(err)
      err.responds_to?( :chain ) && err.chain
    end

    protected def handle_options
      options.cokelib      = [ "cokelib" ]
      options.trace_output = STDERR

      OptionParser.new { |opts|
        opts.banner = "#{Coke.application.name} [-f cokefile] {options} targets..."
        opts.separator ""
        opts.separator "Options are ..."
      }.parse( ARGV )
    end

    protected def collect_command_line_tasks(args)
      @top_level_tasks = [] of String

      if args.is_a? Array(String) 
        args.each do |arg|
          match_data = /^(\W+)=(.*)$/m.match( arg )
          if match_data 
            ENV[match_data[1]] = match_data[2]
          else
            @top_level_tasks << arg unless arg =~ /^-/
          end
        end
      end
      @top_level_tasks << default_task_name if @top_level_tasks.empty?
    end

    protected def find_cokefile_location
      here = Dir.current

      until (filename = have_cokefile)
        Dir.cd ".."
        return { nil, here } if Dir.current == here || options.nosearch
        here = Dir.current
      end
      { filename, here }
    ensure
      Dir.cd Coke.original_dir
    end

    protected def raw_load_cokefile
      cokefile, location = find_cokefile_location

      if ( ! options.ignore_system ) && 
         ( options.load_system || cokefile.nil? ) &&
         system_dir && File.directory? system_dir
        print_cakefile_directory location
      else
      end
    end

    {% if flag? :windows %}
      private def standard_system_dir
        Win32.win32_system_dir
      end
    {% else %}
      private def standard_system_dir
        File.join File.expand_path( "~" ), ".coke"
      end
    {% end %}

    @name             : String?
    @cokefiles        : Array(String)
    @cokefile         : String?
    @pending_imports  : Array(String)
    @imported         : Array(String)
    @loaders          : Hash(String, Coke::Loader)
    @default_loader   : Coke::Loader
    @original_dir     : String
    @system_dir                          = ENV["CAKE_SYSTEM"] || standard_system_dir
    @top_level_dir    : Array(String)
    @top_level_tasks                     = [] of String

    @tty_output       : Bool
    @terminal_columns : Int32

    @options     = OptionStub.new
    @thread_pool = Array(Fiber).new( options.thread_pool_size || Coke.suggested_thread_count - 1 )
    
  end

end
