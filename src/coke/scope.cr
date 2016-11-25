module Coke

  class Scope
    include Indexable(String)

    def path
      map(&to_s).reverse.join( ":" )
    end

    def path_with_task_name(task_name)
      "#{path}:#{task_name}"
    end
  end

end
