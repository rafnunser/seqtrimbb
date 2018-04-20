#########################################
# This class provide methods to install, index, or update internal databases
#########################################

class DatabasesSupportInternal < DatabasesSupport

	#INIT 
	def initialize(dir,info)
		#First SET provided databases constant
		load_repository_info(dir)
		#Load previous info from JSON, if exists. Or create new info structure
		if File.exist?(File.join(dir,'status_info','databases_status_info.json'))
			load_info = JSON.parse(File.read(File.join(dir,'status_info','databases_status_info.json')))
		#Merge! loaded info
			info.merge!(load_info)
	    #Init exit trigger
			@exit_trigger = false
		else
			super(info)
			info['dir'] = dir
			info['installed_databases'] = Array.new
		end
	end
	#SET DEFAULT DATABASES
	def set_databases?(action,list,info) 
		# Replace, remove, add
		if !list.empty? && list[0].to_s.downcase != 'default'       
			super
			#save switch
			info['modified'] = true
			#Set by default           
		else  
			if list[0].to_s.downcase == 'default' || info['databases'].empty?
				info['databases'] = @@repo_info['databases'].sort
				info['modified'] = true
			end
		end
	end
	#CHECKS STRUCTURE
	def check_structure(dir)
		#Build DB structure if it's not present. Exit if dir is not writable by user
		['','fastas','indices','status_info'].map { |d| File.join(dir,d) }.select{ |d| !Dir.exist?(d) }.each do |directory|
			if File.writable?(File.dirname(directory))
				Dir.mkdir(directory)
			else
				STDERR.puts "ERROR. Writing permissions error, unable to create essential databases structure folder #{directory} at: #{File.dirname(dir)}"
				exit(-1)
			end
		end
	end
	#CHECK INFO
	def check_databases(databases,info,bbtools)

		databases = databases.split(/ |,/) if !databases.is_a?(Array)
		if databases.empty?
			STDERR.puts "WARNING. No databases to check."
			return
		end
  		#Info
		STDERR.puts "Checking databases status at #{info['dir']}"
  		#Get info about installation
		installation_status = check_installation_status(info['dir'],databases)
		installation_status['installed'].each { |db| info['installed_databases'].push(db) if !info['installed_databases'].include?(db) }
		if !installation_status['failed'].empty?
			STDERR.puts "ERROR. Databases: #{installation_status['failed'].join(" ")} are empty or not installed.\n Databases can be installed (or reinstalled) with --install_databases option."
			installation_status['failed'].each { |db| info['installed_databases'].delete(db) if info['installed'].include?(db) }
			@exit_trigger = true
			return
		end
			 # if !installation_status['obsolete'].empty?
			 #         STDERR.puts "WARNING. Databases: #{installation_status['obsolete']} are NOT updated. You can update them with -i update"
			 # end 
  		#Check internal databases status
		databases.each do |db|
			check_database_status(db,info,get_current_fastas(db,info['dir']))
		end            
  		#Get info for obsolete databases
		if !info['obsolete_databases'].empty?
			STDERR.puts "The following databases indices are obsolete:\n #{info['obsolete_databases'].join("\n\s")}"
			get_dbs_info(info['obsolete_databases'].select { |d| databases.include?(d) },info)
			info['modified'] = true                   
			#Check writing permissions
			if !File.writable?(File.join(info['dir'],'indices')) || !File.writable?(File.join(info['dir'],'status_info'))
				STDERR.puts "ERROR!. Impossible to update databases (#{info['obsolete_databases'].join(" ")}) index because folders: #{File.join(info['dir'],'indices')} and/or #{File.join(info['dir'],'status_info')} are not writable. Please contact your admin to update your databases or add -c tag to avoid this step."
				exit(-1)
			else 
			#Update index!     
				update_index(info['obsolete_databases'].select { |d| databases.include?(d) },info,bbtools)
			end
		else
			STDERR.puts "All databases indices are updated"
		end

	end
#Get current fastas
	def get_current_fastas(db,dir)
		return Dir[File.join(dir,'fastas',db,"*.fasta*")].sort 			 
	end
  #GET DATABASES INFO
	def get_dbs_info(databases,info)		
		databases = databases.split(/ |,/) if !databases.is_a?(Array)
		databases.each do |db_name|
		# DB name
		info[db_name]['name'] = db_name
		#LOAD (or re-load) PATHS
			#Fastas folder path
			info[db_name]['path'] = File.join(info['dir'],'fastas',db_name)
			#Index path
			info[db_name]['index'] = File.join(info['dir'],'indices',db_name)
			#Error file path
			info[db_name]['update_error_file'] = File.join(info['dir'],'status_info','update_stderror_'+db_name+'.txt')  
		end
		#STATUS INFO(fastas,size,name...)
		super
	end

end