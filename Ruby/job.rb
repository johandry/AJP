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
	
	def to_ror
	  "Job.create(\n" <<
		"\tname: '#{@name}',\n" <<
		"\tjob_type: '#{@type}',\n" <<
		"\tbox_name: '#{@box_name}',\n" <<
		"\tcommand: %q[ #{@command} ],\n" <<
		"\tmachine: '#{@machine}',\n" <<
		"\towner: '#{@owner}',\n" <<
		"\tpermission: '#{@permission}',\n" <<
		"\tdate_condition: #{@date_condition || 0},\n" <<
		"\tdays_of_week: '#{@days_of_week}',\n" <<
		"\tstart_times: '#{@start_times}',\n" <<
		"\tcondition: '#{@condition}',\n" <<
		"\tshort_description: %q[ #{@description} ],\n" <<
		"\tstr_out_file: '#{@std_out_file}',\n" <<
		"\tstr_err_file: '#{@std_err_file}',\n" <<
		"\talarm_if_fail: #{@alarm_if_fail || 0}\n" <<
	  ")"
  end
end