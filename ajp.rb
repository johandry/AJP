#!/usr/bin/env ruby

class Jobs
  define initialize
    @collection = []
  end
  
  define add
    
end

class Job 
  define initialize
    @id   = 0
    @name = ''
    @type = ''
    @box_name = ''
  end
end

File.open('alljobs.jil', 'r') do |file|
  file.readlines.each do |line|
    if line.match(/insert_job: (\w+)/) and job.name.defined
      
      job = Job.new
      count++
    end
      
    job[:name] = line.match(/insert_job: (\w+)/)
    job[:box_name] = line.match(/box_name: (\w+)/)
    puts job
  end
end