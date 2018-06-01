#########################################
# This class provide methods to handle installation, indexing, or updating external and internal databases
#########################################

class DatabasesSupportHandler

	attr_accessor :info 
	attr_accessor :external_db_info 
#INIT
	def initialize(cores,dir,bbtools)			 
		require 'databases_support.rb'
  #Instance variables
	  #Databases path
		@dir = dir
	  #Cores
		@cores = cores
	  #BBtools
		@bbtools = bbtools
	end
#INTERNAL METHODS
  #INIT 
	def init_internal(options = {})			 
		require 'databases_support_internal.rb'
	 #Initialize Internal databases support
		@internal_databases = DatabasesSupportInternal.new(@dir,@info={})
	 #Set databases
		@internal_databases.set_databases?(options[:databases_action],options[:databases_list],@info)
	end
  #MAINTENANCE
	def maintenance_internal(options)			 
		#Build DB structure if it's not present
		@internal_databases.check_structure(@dir)
		#IF it is requested, proceeds to install or reinstall databases
		if options[:install_db]
			require 'databases_support_install.rb'
			@databases_installer = DatabasesSupportInstall.new(info)
			if !options[:install_db_name].empty? && options[:install_db_name].first.downcase == 'update'
				@databases_installer.update(info)
			else
				@databases_installer.install(options[:install_db_name],info)
			end
			trigger_exit(true)
		end
		#Unless -c option is passed, proceeds to check databases status
		if options[:check_db]
			@internal_databases.check_databases(@info['databases'],@info,@bbtools)
			trigger_exit(true) if @internal_databases.exit?
		else
			STDERR.puts "Skipping checking and indexing databases step."
		end

	end
  #SAVE?
	def save?
		# True if info has been modified
		return true if @info.key?('modified')
	end

#EXTERNAL METHODS
  #INIT
	def init_external
  		#Initialize external DBs support
		require 'databases_support_external'
		#Init external class and create an external_db_info hash
		@external_databases = DatabasesSupportExternal.new(@external_db_info={})
	end
  #ADD database
	def set_external(paths_to_dbs)			 
		init_external?
		@external_databases.set_databases?('add',paths_to_dbs,@external_db_info)
	end
  #MAINTENANCE
	def maintenance_external(paths_to_dbs)			
		@external_databases.check_databases(paths_to_dbs,@external_db_info,@bbtools)
		trigger_exit(false) if @external_databases.exit?

	end
  #SET EXCLUDING! ...
	def set_excluding(refs)			 
		init_external?
		db_name = @external_databases.update_database_by_refs(refs,@external_db_info,@bbtools)             
		trigger_exit(false) if @external_databases.exit?             
		return db_name
	end
  #TEST if INIT
	def init_external?	 
		if !defined?(@external_databases)
			init_external
		end
	end
#LIST DATABASES
	def list_databases(list)
		require 'databases_support_list.rb'
		DatabasesSupportList.new(list,@info)
	end
#TRIGGER EXIT
	def trigger_exit(save_trigger)
		save_json(@info,File.join(@dir,'status_info','databases_status_info.json')) if (save? && save_trigger)
		STDERR.puts "Exiting ..."
		exit(-1)
	end
#SAVE JSON
	def save_json(info,file)			 
		if !File.writable?(File.dirname(file))
			STDERR.puts "Error in writing permissions. Unable to write databases info JSON."
			return
		end
		STDERR.puts"Saving internal databases info"
		File.open(file,"w") do |f|
			f.write(JSON.pretty_generate(info.except('modified')))
		end			 
	end
#GET INFO
	def get_info(*levels)
		## TODO!...check every level
		if check_levels(@info,levels) #Database is internal
			return @info.dig(*levels)
		elsif check_levels(@external_db_info,levels) #Database is external
			return @external_db_info.dig(*levels)
		else 
			STDERR.puts '#{levels.join('')} info does not exists. Returning nil'
			return nil
		end
	end
#check levels
	def check_levels(in_hash,levels)			
		look_h = in_hash
		levels.each do |level|
			if look_h.is_a?(Hash)
				if look_h.key?(level)
					look_h = look_h.dig(level)
				else
					return false
				end
			elsif look_h.is_a?(Array)
				if look_h[level]
					look_h = look_h.dig(level)
				else
					return false
				end
			end
		end
		return true
	end
#CHECK ON DATABASE STATUS (INFO LEVEL). Return found errors.
	def check_status(info,database)				 
		error = ['installed','indexed'].select { |c| info.key?("#{c}_databases") && !info["#{c}_databases"].include?(database) }
		error << 'present on internal databases list' if !info['databases'].include?(database)
		return error
	end

end