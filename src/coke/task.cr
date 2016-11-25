require "./application"
require "./scope"
require "./invocation_exception_mixin"

module Coke

  class Task
    property prerequisites
    getter   actions
    property application
    getter   scope
    getter   locations
    getter   already_invoked
    setter   sources

    def initialize(task_name, app)
      @name            = task_name.to_s
      @prerequisites   = [] of Array(String)
      @actions         = [] of Array(String)
      @already_invoked = false
      @comments        = [] of Array(String)
      @application     = app
      @scope           = app.current_scope
      @arg_names       = nil
      @locations       = [] of Array(String)
    end

    def source
      sources.first
    end

    def sources
      if defined? @sources
        @sources
      end
      prerequisites
    end

    def prerequisites_tasks
      prerequisites.map { |pre| lookup_prerequisites pre }
    end

    def all_prerequisite_tasks
      seen = {} of String => Coke::Task
      collect_prerequisites seen
      seen.values
    end

    def to_s
      name
    end

    def inspect
      "#<#{self.class} #{name} => [#{prerequisites.join( ", " )}]>"
    end

    protected def collect_prerequisites(seen)
      prerequisites_tasks.each do |task|
        next if seen[task.name]
        seen[task.name] = task
        task.collect_prerequisites seen
      end
    end

    private def lookup_prerequisites(prerequisite_name)
      scoped_prerequisite_task = application[prerequisite_name, @scope]

      if scoped_prerequisite_task == self then
        unscoped_prerequisite_task = application[prerequisite_name]
      end
      unscoped_prerequisite_task || scoped_prerequisite_task
    end

    @name            : String?
    @prerequisites   : Array(String)
    @actions         : Array(String)
    @already_invoked : Bool
    @comments        : Array(String)?
    @application     : Coke::Application
    @scope           : Coke::Scope
    @arg_names       : Array(String)?
    @locations       : Array(String)?
  end

end
