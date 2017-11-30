#########################################
# This class provide shared methods to install, index, or update external and internal databases
#########################################

class DatabasesSupport

      @@provided_databases = ['adapters','contaminants','contaminants_seqtrim1','cont_bacteria','cont_fungi','cont_mitochondrias','cont_plastids','cont_ribosome','cont_viruses','vectors']
      @@provided_databases.freeze
#INIT
	    def initialize(info)

             info['databases'] = Array.new
             info['indexed_databases'] = Array.new
             info['obsolete_databases'] = Array.new

	    end
#METHODS
  #SET DATABASES
      def set_databases?(action,list,info)

             case action.downcase
                     when 'replace'                             
                             info['databases'] = list
                     when 'add'
                             list.map { |d| info['databases'].push(d) if !info['databases'].include?(d) }
                     when 'remove'
                             list.map { |d| info['databases'].delete(d) if info['databases'].include?(d) }
             end
             #Clean up
             ['indexed','obsolete'].map { |key| (info["#{key}_databases"] - info['databases']).map { |d| info["#{key}_databases"].delete(d) if info["#{key}_databases"].include?(d) } }
             
      end
  #GET DATABASES INFO
      def get_dbs_info(databases,info)

             databases = databases.split(/ |,/) if !databases.is_a?(Array)
             databases.each do |db_name|
         # STATUS INFO (fastas,size...
               # Fastas paths and list
                     info[db_name]['fastas'] = File.directory?(info[db_name]['path']) ? Dir[File.join(info[db_name]['path'],"*.fasta*")].sort : [info[db_name]['path']]
                     info[db_name]['list'] = info[db_name]['fastas'].map { |fasta| File.basename(fasta).sub(/\Wfasta(\Wgz)?/,'').sub(/_/,' ') }
               # DB size
                     db_size = info[db_name]['fastas'].map { |file| File.size?(file) }.inject(:+)
                     info[db_name]['size'] = db_size
             end

      end
  #CHECKS DB STATUS
      def check_database_status(db_name,info,current_fastas)

                     if info.key?(db_name) && !info['obsolete_databases'].include?(db_name) # Exists a previous execution 
                             check_index(db_name,info,current_fastas)
                     elsif !info.key?(db_name) # First time update
                             info['obsolete_databases'] << db_name
                             info[db_name] = {}
                     end

      end
  #CHECKS INDEX
      def check_index(db_name,info,current_fastas)   

  # Check point (Is not previously updated OR Current fastas != Old fastas)
             if current_fastas != info[db_name]['fastas'] || !Dir.exist?(File.join(info[db_name]['index'],'ref'))
                     info['obsolete_databases'] << db_name 
                     info['indexed_databases'].delete(db_name) if info['indexed_databases'].include?(db_name)
             end

      end
   #UPDATE INDEX
      def update_index(databases,info,bbtools)
        
             exit_trigger = false
             databases = databases.split(/ |,/) if !databases.is_a?(Array)
             STDERR.puts "Updating databases indices:"
           # Updating obsolete databases
             databases.each do |db_name| 
           # Removing old index,and old stderror. Make new index folder
                     FileUtils.rm_rf(info[db_name]['index']) if Dir.exist?(info[db_name]['index'])
                     FileUtils.rm(info[db_name]['update_error_file']) if File.exist?(info[db_name]['update_error_file'])
                     Dir.mkdir(info[db_name]['index'])
           # Loading BBtools module and cmd execution
                     cmd = bbtools.load_bbsplit({'ref' =>  info[db_name]['path'], 'path' => info[db_name]['index'], 'in' => nil, 'out' => nil, 'int' => nil, 'redirection' => ['2>',info[db_name]['update_error_file']]})
                     system(cmd)
           # Look for errors
                     error = check_update_error(db_name,info)
                     if !error
           #Add database to indexed_databases array
                             info['indexed_databases'] << db_name if !info['indexed_databases'].include?(db_name)
                             info['obsolete_databases'].delete(db_name) if info['indexed_databases'].include?(db_name)
           # Add index size
                             index_size = Dir[File.join(info[db_name]['index'],'ref',"*/*/*")].map { |file| File.size?(file) }.inject(:+)
                             info[db_name]['index_size'] = index_size
                     else
           #Exit_trigger = true if database indexing failed
                             exit_trigger = error if !exit_trigger
           #Remove failed index
                             FileUtils.rm_rf(info[db_name]['index']) 
                     end              
             end
           #Exit if at least one error was found
             if exit_trigger
                     STDERR.puts"One o more errors were found in databases update"
                     if info.key?('modified')
                             STDERR.puts "Saving internal databases info"
                             File.open(File.join(File.dirname(info[databases.first]['update_error_file']),'databases_status_info.json'),"w") do |f|
                                     f.write(JSON.pretty_generate(info.except('modified')))
                             end 
                     end
                     STDERR.puts "Exiting"                    
                     exit(-1)
             end 

      end
   #CHECK UPDATE ERRORS
      def check_update_error(database,info)
           
           #Update error file exists and index_folder/ref folder exists
             if Dir.exist?(File.join(info[database]['index'],'ref')) && File.exist?(info[database]['update_error_file'])
                   #Open stderror file and look for errors    
                     open_error = File.open(info[database]['update_error_file'])
                     open_error.each do |line|
                             line.chomp!
                             if !line.empty? && ( (line =~ /Error/) || (line =~ /Exception in thread/) )
                                     STDERR.puts "ERROR! Failed to update #{database} database index:\n\t#{line}\nFor more details: #{info[database]['update_error_file']}"
                                     return true
                             end 
                     end
                     open_error.close
                   #Info if no error was found
                     STDERR.puts "\s#{database} database index is updated"
                     return false
             else
                     STDERR.puts "ERROR. Unable to find #{database} database index (#{info[database]['index']}) or update error file (#{info[database]['update_error_file']}). Database is obsolete."
                     return true
             end

      end
   #CHECK INSTALLATION
      def check_installation(dir,databases)

             databases = databases.split(/ |,/) if !databases.is_a?(Array)
             installed_dbs = databases.select { |d| ( Dir.exist?(File.join(dir,'fastas',d)) || !Dir[File.join(dir,'fastas',d,"*.fasta*")].empty? ) }
             return installed_dbs

      end

end