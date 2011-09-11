require File.expand_path('spec/spec_helper')

RbConfig::CONFIG["host_os"] = "flux_capacitor99.312.4"
puts Parallel.processor_count
