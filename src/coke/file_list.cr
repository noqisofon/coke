module Coke

  class FileList
    def self.glob(pattern)
      Dir.glob( pattern ).sort
    end
  end

end
