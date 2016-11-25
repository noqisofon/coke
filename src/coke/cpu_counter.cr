module Coke

  class CpuCounter
    def self.count
      new.count_with_default
    end

    def count_with_default(default_value = 4) : Int32
      count || default_value
    rescue
      default_value
    end

    def count : Int32
      4
    end
  end

end
