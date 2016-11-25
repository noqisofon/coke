require "./application"

module Coke
  extend self

  @@application = Coke::Application.new
  @@cpu_count   : Int32    = Coke::CpuCounter.count

  def application
    @@application
  end

  def application=(value)
    @@application = value
  end

  def suggested_thread_count
    @@cpu_count + 4
  end

  def original_dir
    application.original_dir
  end

end
