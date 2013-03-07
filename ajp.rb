#!/usr/bin/env ruby

class Job

	attr_accessor :id, :name, :type, :box_name, :command, :machine, :owner, :permission, :date_condition, :days_of_week, :start_times, :condition, :description, :std_out_file, :std_err_file, :alarm_if_fail

	def initialize (id)
		@id				= id
		@name			= ''
		@type			= ''
		@box_name		= ''
		@command		= ''
		@machine		= ''
		@owner			= ''
		@permission		= ''
		@date_condition	= ''
		@days_of_week	= ''
		@start_times	= ''
		@condition		= ''
		@description	= ''
		@std_out_file	= ''
		@std_err_file	= ''
		@alarm_if_fail	= ''
	end

	def to_s
		"ID: #{@id}\n" << 
		"Name: #{@name}\n" <<
		"Type: #{@type}\n" <<
		"Box Name: #{@box_name}\n" <<
		"Command: #{@command}\n" <<
		"Machine: #{@machine}\n" <<
		"Owner: #{@owner}\n" <<
		"Permission: #{@permission}\n" <<
		"Date Condition: #{@date_condition}\n" <<
		"Days of Week: #{@days_of_week}\n" <<
		"Start Times: #{@start_times}\n" <<
		"Condition: #{@condition}\n" <<
		"Description: #{@description}\n" <<
		"STDOUT File: #{@std_out_file}\n" <<
		"STDERR File: #{@std_err_file}\n" <<
		"Alarm if Fails: #{@alarm_if_fail}"
	end
end

class Jobs

	def get_jobs_from_jil (filename)
		job = Job.new(1)
		id=2
		File.open(filename, "r").each_line do |line|
			if( /insert_job:/.match(line) ) 
				#@jobs.push(job)
				puts job
				puts "\n"
				job = Job.new(id)
				id += 1
			end
			
			job.name 			= $1 if /insert_job: (\w+)/.match(line)
			job.type 			= $1 if /job_type: (\w+)/.match(line)
			job.box_name		= $1 if /box_name: (\w+)/.match(line)
			job.command			= $1 if /command: (.+)/.match(line)
			job.machine			= $1 if /machine: (.+)/.match(line)
			job.owner			= $1 if /owner: (.+)/.match(line)
			job.permission		= "\"#{$1}\"" if /permission: (.+)/.match(line)
			job.date_condition	= $1 if /date_conditions: (.+)/.match(line)
			job.days_of_week	= "\"#{$1}\"" if /days_of_week: (.+)/.match(line)
			job.start_times		= "\"#{$1}\"" if /start_times: "(.+)"/.match(line)
			job.condition		= $1 if /condition: (.+)/.match(line)
			job.std_out_file	= $1 if /std_out_file: (.*)/.match(line)
			job.std_err_file	= $1 if /std_err_file: (.*)/.match(line)
			job.alarm_if_fail	= $1 if /alarm_if_fail: (.+)/.match(line)
			
		end
	end
	
	def initialize(jil_filename)
		@jobs = Array.new
		get_jobs_from_jil(jil_filename)
	end

	def toYAML
	end
end


jobs = Jobs.new("alljobs.jil")
jobs.toYAML
