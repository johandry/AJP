class Job

	attr_accessor :id, :name, :type, :box_name, :command, :machine, :owner, :permission, :date_condition, :days_of_week, :start_times, :condition, :description, :std_out_file, :std_err_file, :alarm_if_fail

	def initialize (id, name = '', type = '', box_name = '', command = '', machine = '', owner = '', permission = '', date_condition = 0, days_of_week = '', start_times = '', condition = '', description = '', std_out_file = '', std_err_file = '', alarm_if_fail = 0)
		@id				= id
		@name			= name
		@type			= type
		@box_name		= box_name
		@command		= command
		@machine		= machine
		@owner			= owner
		@permission		= permission
		@date_condition	= date_condition
		@days_of_week	= days_of_week
		@start_times	= start_times
		@condition		= condition
		@description	= description
		@std_out_file	= std_out_file
		@std_err_file	= std_err_file
		@alarm_if_fail	= alarm_if_fail
	end

	def to_s
	  job_type = (@type == 'c')?"Job":(@type == 'b')?"Box":(@type == 'f')?"Filewatcher":"Unknown Job Type"
	  "#{job_type} #{@name}\n" <<
		"\tID: #{@id}\n" << 
		"\tName: #{@name}\n" <<
		"\tType: #{@type}\n" <<
		"\tBox Name: #{@box_name}\n" <<
		"\tCommand: #{@command}\n" <<
		"\tMachine: #{@machine}\n" <<
		"\tOwner: #{@owner}\n" <<
		"\tPermission: #{@permission}\n" <<
		"\tDate Condition: #{@date_condition}\n" <<
		"\tDays of Week: #{@days_of_week}\n" <<
		"\tStart Times: #{@start_times}\n" <<
		"\tCondition: #{@condition}\n" <<
		"\tDescription: #{@description}\n" <<
		"\tSTDOUT File: #{@std_out_file}\n" <<
		"\tSTDERR File: #{@std_err_file}\n" <<
		"\tAlarm if Fails: #{@alarm_if_fail}\n"
	end
end