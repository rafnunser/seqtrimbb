#########################################
# This class provide methods to install, index, or update external databases
#########################################

class DatabasesSupportExternal < DatabasesSupport

#EXTERNAL METHODS
  #CHECKS INFO
	def check_databases(databases,info,bbtools)
		databases = databases.split(/ |,/) if !databases.is_a?(Array)
  #Check external databases status
		databases.each do |db|
			check_database_status(db,info,get_current_fastas(db))
		end
  #Get info for obsolete databases
		if !info['obsolete_databases'].empty?
			STDERR.puts "External databases: #{info['obsolete_databases'].join(" ")} are obsolete"
			get_dbs_info(info['obsolete_databases'].select { |d| databases.include?(d) },info)
			update_index(info['obsolete_databases'].select { |d| databases.include?(d) },info,bbtools)
		else
			STDERR.puts "All external databases are updated"
		end
	end
 #Get current fastas
	def get_current_fastas(db)
		if File.directory?(db)
			return Dir[File.join(db,"*.fasta*")].sort
		else
			return [db]
		end			 
	end
  #GET DATABASES INFO
	def get_dbs_info(databases,info)			 
		databases = databases.split(/ |,/) if !databases.is_a?(Array)
		databases.each do |db|
		 #LOAD (or re-load) PATHS --- Case internal | internal 
			info[db]['name'] = File.basename(db).gsub(/\Wfasta(\Wgz)?/,'')
			#Set a database directory
			db_dir = File.directory?(db) ? db : File.dirname(db)
			#Fastas folder path
			info[db]['path'] = db
			#Index path. First test if db directory is writable, then set a writable index path
			if File.writable?(db_dir)
				info[db]['index'] = File.join(db_dir,'index')
			else
				info[db]['index'] = File.join(OUTPUT_PATH,'temp_indices',info[db]['name'])
				Dir.mkdir(File.join(OUTPUT_PATH,'temp_indices')) if !Dir.exist?(File.join(OUTPUT_PATH,'temp_indices'))
			end 
			#Error file path
			info[db]['update_error_file'] = File.join(info[db]['index'],'update_stderror_'+info[db]['name']+'.txt')                  
		end
		 # STATUS INFO (fastas,size...
		super
	end
   #UPDATE INDEX 
	def update_database_by_refs(refs,info,bbtools)
			 
		#Database essential hash building
		db = File.basename(File.dirname(refs.first))+'_excluding'
		i = 1
		while info.key?(db)
			db = db+'_'+i.to_s
			i += 1
		end
		info[db] = {}           
		info[db]['name'] = db
		info[db]['path'] = refs.join(',')
		info[db]['index'] = File.join(OUTPUT_PATH,'temp_indices',info[db]['name'])
		Dir.mkdir(File.join(OUTPUT_PATH,'temp_indices')) if !Dir.exist?(File.join(OUTPUT_PATH,'temp_indices'))
		info[db]['update_error_file'] = File.join(info[db]['index'],'update_stderror_'+info[db]['name']+'.txt')
		#Update!
		update_index(db,info,bbtools)
		#Return
		return db	
	end

end