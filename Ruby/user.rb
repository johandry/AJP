class User
	attr_accessor :id, :name, :email
	
	def initialize (id, name, email)
		@id = id
		@name = name
		@email = email
	end
	
	def to_s
		"User #{@name}\n" <<
		"\tID: #{@id}\n" <<
		"\tName: #{@name}\n" <<
		"\tEmail: #{@email}\n"
	end
end