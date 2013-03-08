class Ownership
	attr_accessor :id, :user_id, :job_id, :check_on
	
	def initialize (id, user_id, job_id, check_on)
		@id 		= id
		@user_id 	= user_id
		@job_id  	= job_id
		@check_on 	= check_on
	end
end