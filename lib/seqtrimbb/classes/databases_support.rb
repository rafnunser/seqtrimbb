#########################################
# This class provide methods to install, index, or update external and internal databases
#########################################

class DatabasesSupport

	  attr_accessor :info 
	  attr_accessor :external_db_info 
    attr_reader :save_info
#INIT
	     def initialize(options,dir,bbtools)

  #Instance variables
      #STBB provided databases
             @provided_databases = ['adapters','contaminants','contaminants_seqtrim1','cont_bacteria','cont_fungi','cont_mitochondrias','cont_plastids','cont_ribosome','cont_viruses','vectors']
      #Save changes trigger. False by default.
             @save_info = false
      #Databases path
             @dir = dir
      #Cores
             @cores = options[:workers]
      #BBtools
             @bbtools = bbtools
      #Load previous info from JSON, if exists. Or create new info structure
             if File.join(@dir,'status_info','databases_status_info.json').exist?
                     @info = JSON.parse(File.read(File.join(@dir,'status_info','databases_status_info.json')))
             else
                     @info = {}
                     @info['databases'] = Array.new
                     @info['installed_databases'] = Array.new
                     @info['indexed_databases'] = Array.new
                     @info['obsolete_databases'] = Array.new
             end
      #Set databases and return save trigger
             save_point = set_databases(options[:databases_action],options[:databases_list],@info)
             save?(save_point)

	    end

#INTERNAL METHODS
  #INIT MAINTENANCEC
      def maintenance(options)

          #Build DB structure if it's not present
            ['','fastas','indices','status_info'].map{ |d| File.join(@dir,d) }.select{ |d| !Dir.exist?(d) }.each do |dir|
                   if File.writable?(File.dirname(dir))
                           Dir.mkdir(dir)
                   else
                           STDERR.puts "ERROR. Writing permissions error, unable to create essential databases structure folder #{dir} at: #{File.dirname(dir)}"
                           exit(-1)
                   end
            end
          #IF it is requested, proceeds to install or reinstall databases
            if options[:install_db]
                     install_databases(options[:install_db_name])
                     save_json if @save_info
                     exit(-1)
            end
          #Checks if all databases (in @info['databases']) are installed. If databases folder is not present or  is empty, exit
            failed_dbs = @info['databases'] - check_installation(@info['databases'])
            if !failed_dbs.empty?
                 	 STDERR.puts "ERROR. Databases: #{failed_dbs.join(" ")} are empty or not installed.\n Databases can be reinstalled with --install_databases option."
                   exit(-1)
            end
          #Unless -c option is passed, proceeds to check databases status
            if options[:check_db]
                     check_internal_db_info(@info['databases'])
               #Update obsolete databases
                     update_index(@info['obsolete_databases'])
            end

      end
  #INSTALL DATABASES
      def install_databases(databases_list)

         #Add STBBs provided databases if list is empty. Avoid reinstalling databases.
             if databases_list.empty?
                     databases_list = @provided_databases - check_installation(@provided_databases)
                  #Exit if it is still empty
                     if databases_list.empty?
                             STDERR.puts "Exiting. All databases are installed."
                             exit(-1)
                     end   
             end
         #Checks writing permissions
             if !File.writable?(File.join(@dir,'fastas'))
                     STDERR.puts "ERROR. Writing permissions error, unable to install databases at: #{@dir}"
                     exit(-1)
             end
         #Checks dbs origin
             databases_list.each do |database|
                     STDERR.puts "Installing database #{database} at: #{File.join(@dir,'fastas')}"
         #Remove databases files to reinstall it, if it's installed
                     case database
         #if they're provided by STBB, download it, unpack it, and add it to obsolete databases
                             when @provided_databases.include?(database)
                                       reinstall_check(database)
                                       download_and_unpack(database)
         #if they're an external source, copy (only fasta files), and add it to obsolete databases
                             when Dir.exist?(database)
                                       reinstall_check(File.basename(database,"*."))
                                       copy_and_place(database)
                     end
             end
         #Checks if they're properly installed
             installed_databases = check_installation(databases_list)
             if (databases_list - installed_databases).empty?
                     STDERR.puts "Completed installation of databases: #{databases_list.join("\n")}"
             else
                     STDERR.puts "ERROR. Failed to install databases: #{(databases_list - installed_databases).join("\n")}"
                     exit(-1) if installed_databases.empty?
             end
             installed_databases.map { |d| @info['installed_databases'] << d if !@info['installed_databases'].include?(d) }
         #ADD database to @info['databases']
             #save_point = set_databases('add',installed_databases,@info)
             #save?(save_point)
         #Checks and update databases
             check_internal_db_info(installed_databases)
             update_index(insta11ed_databases,@info)

      end
     #Checks previous databases installation
      def reinstall_check(database)
           # Delete folder from Databases fastas directory and delete old database info
             if Dir.exist?(File.join(@dir,'fastas',database))
                     STDERR.puts "A previous installation of database #{database} has been detected. Reinstalling..."
                     FileUtils.rm_rf(File.join(@dir,'fastas',database)) 
             end
             @info.delete(database) if @info.key?(database)
      
      end
     #Download database
      def download_and_unpack(database)

          #Download database. From google drive temporary, Hash to store databases Google Drives IDs
             file_out = File.join(@dir,'fastas',database,'.zip')
             databases_ids = {'adapters' : '3i91nbgplyl4s34',
                              'contaminants' : '2fnqjc9hx4dwank' ,
                              'contaminants_seqtrim1' : 'wgj4czo0cp6mm9p',
                              'cont_bacteria' : 'zsoitcmvpokpnx8',
                              'cont_fungi' : 'fuc9xb39lfr3uew' ,
                              'cont_mitochondrias' : 'myvfzlr1eo7zgin',
                              'cont_plastids' : 'uci58iddo6rlqif',
                              'cont_ribosome' : 'faqi2jzv3go973p',
                              'cont_viruses'  : 'kih7xnitye0q858',
                              'vectors' : 'fgn2e4v0mrhtiak'}
             url = "\"https://www.dropbox.com/s/#{databases_ids[database]}?dl=0\""
             download_cmd = "curl -L -o #{file_out} #{url}"
             STDERR.puts "Downloading database: #{database}"
             system(download_cmd)
          #Unpack   
             unzip_cmd = "unzip #{file_out} -d #{File.join(@dir,'fastas')} && rm #{file_out}"
             STDERR.puts "Unzipping database: #{database}"
             system(unzip_cmd)

      end
     #Copy database
      def copy_and_place(database)

          #Databases name, files and checkpoints
             db_name = File.basename(database,"*.")
          # File or directory. For file, checks if it is a fasta file
             if File.directory?(database)
                     db_files = Dir[File.join(database,"*.fasta*")]
             elsif File.file?(database) && File.basename(database) =~ /^\w*\Wfasta(\Wgz)?/
                     db_files = database
             end
          #Make database directory
             Dir.mkdir(File.join(@dir,'fastas',db_name))
          #Copy all fasta files in path
             FileUtils.cp db_files File.join(@dir,'fastas',db_name)

      end
     #Installation check
      def check_installation(databases)

             installed_dbs = databases.select { |d| ( !Dir.exist?(File.join(@dir,'fastas',d)) || !Dir[File.join(@dir,'fastas',d,"*.fasta*")].empty? ) }
             return installed_dbs

      end
  #CHECK INFO
      def check_internal_db_info(databases)

  #Info
             STDERR.puts "Checking databases indices at #{@dir} for updates"
  #Check databases status
             databases.each do |db_name|
                     if @info.key?(db_name) && !@info['obsolete_databases'].include?(db_name) # Exists a previous execution 
                             current_fastas = Dir[File.join(@dir,'fastas',db_name,"*.fasta*")].sort   
                             check_index(db_name,current_fastas,@info)
                     else # Firs time updated 
                             @info['obsolete_databases'] << db_name
                             @info[db_name] = {}
                     end
             end
  #Get info for obsolete databases
             if !@info['obsolete_databases'].empty?
                     get_dbs_info(@info['obsolete_databases'].select { |d| databases.include?(d) },@info)
                     save?(true)
             end

      end
  #SAVE?
      def save?(save_point)

             @save_info = save_point if !@save_info

      end

#EXTERNAL METHODS
  #INIT
	    def init_external(paths_to_dbs)

  #Initialize external DBs support
          #Creates external_db_info hash if doesn't exists
             if !defined?(@external_db_info).nil?
                     @external_db_info = {}
                     @external_db_info['databases'] = []
             end
          #Get/update info
             check_external_db_info(paths_to_dbs)

	    end
  #CHECKS INFO
      def check_external_db_info(databases)

  #Check previous indexed and creates obsolete databases
             @external_db_info['indexed_databases'] = [] if !@external_db_info.key?('indexed_databases') 
             @external_db_info['obsolete_databases'] = [] if !@external_db_info.key?('obsolete_databases')
  #Check external databases status
             databases.each do |db|
                     if @info.key?(db) # Exists a previous execution
                             if File.directory?(db)
                                     current_fastas = Dir[File.join(db,"*.fasta*")].sort
                             else
                                     current_fastas = db
                             end
                             check_index(db_name,current_fastas,@external_db_info) if !@external_db_info['obsolete_databases'].include?(db)
                     else # Firs time updated 
                             @external_db_info['databases'] << db
                             @external_db_info['obsolete_databases'] << db
                             @external_db_info[db_name] = {}
                     end
             end
  #Get info for obsolete databases
             get_dbs_info(@external_db_info['obsolete_databases'],@external_db_info)
      end

#SHARED METHODS
  #SET DEFAULT DATABASES
      def set_databases(action,list,info)
             
             #save switch
             res = false
             # Replace, remove, add
             if !list.empty? && list[0].downcase != 'default'       
                     case action.downcase
                             when 'replace'                            	
                                     info['databases'] = list
                             when 'add'
                                     list.map { |d| info['databases'].push(d) if !info['databases'].include?(d)}
                             when 'remove'
                                     list.map { |d| info['databases'].delete(d) if info['databases'].include?(d)}
                     end
                     res = true
             #Set by default           
             else  
                     if list[0].downcase == 'default' || info['databases'].empty?
                             info['databases'] = @provided_databases
                             res=true
                     end
             end
             #return switch
             return res

      end
  #LIST databases ids or databases
      def list_databases(list)
        #Load all installed databases
             all_databases = Dir[File.join(@dir,'fastas',"*")].select { |d|  (File.directory?(d) && ![".",".."].include?(d)) }
        #Array to store all databases to list'
             to_list = Array.new
        # if dbs list is empty, list all avalaible databases
             if list.empty?
             	       to_list << 'all'
             else
                     #Reject from the dbs list all not present databases. List avalaible databases
                     rejected = list.select { |d| !all_databases.include?(d) }
                     if !rejected.empty?
                             rejected.map { |r| puts "Database #{r} is not present" if r != 'all'}
                             to_list << 'all'
                     end
                     #Add dbs
                     list.map { |d| to_list << d if !rejected.include?(d) }
             end
            #List all dbs entries, and all avalaible databases if needed
             to_list.each do |db_name|
             	     case db_name
             	             when 'all'
                                     puts "Installed databases: (databases at #{@dir}"
                                     puts "-"
                                     all_databases.map { |d| puts d }
                                     puts ""
                                     puts "Databases provided by SeqTrimBB:"
                                     puts "-"
                                     @provided_databases.map { |d| puts d }
                                     puts ""
                                     puts "Indexed databases:"
                                     puts "-"
                                     @info['indexed_databases'].map { |d| puts d } if (@info.keys?('indexed_databases') && !@info['indexed_databases'].empty?)
                                     puts "---"
                           else
                                     puts "Entries at #{db_name} database:"
                                     puts "-"
                                     @info[db_name]['fastas'].map { |f| puts f } if @info.key?(db_name)
                                     puts ""                        
             end

      end
  #CHECKS DB STATUS
      def check_index(db_name,current_fastas,info)   
  
  # Check point (Is not previously updated OR Current fastas != Old fastas)
             if current_fastas != info[db_name]['fastas'] || !Dir.exist?(File.join(info[db_name]['index'],'ref'))
                     info['obsolete_databases'] << db_name 
                     info['indexed_databases'].delete(db_name) if info['indexed_databases'].include?(db_name)
             end

      end
  #GET DATABASES INFO
      def get_dbs_info(databases,info)

             databases.each do |db|
                     db_type = !File.exist?(db) ? 'internal' : 'external'
         #LOAD (or re-load) PATHS --- Case internal | internal
                     case db_type
                 	           when 'internal'
                 	     	             db_name = db
                 	   #Fastas folder path
                                     info[db_name]['path'] = File.join(@dir,'fastas',db_name)
                       #Index path
                                     info[db_name]['index'] = File.join(@dir,'indices',db_name)
                       #Error file path
                                     info[db_name]['update_error_file'] = File.join(@dir,'status_info','update_stderror_'+db_name+'.txt')  
                 	           when 'external'
                 	     	             db_name = File.basename(db,"*.")
                 	   #Set a db_dir (Dir:File)
                 	                   db_dir = File.directory?(db) ? db : File.dirname(db)
                 	   #Fastas folder path
                 	     	             info[db_name]['path'] = db
                 	   #Index path. First test if db directory is writable, then set a writable index path
                 	                   if File.writable?(db_dir)
                                             info[db_name]['index'] = File.join(db_dir,'index')
                                     else
                                             info[db_name]['index'] = File.join(OUTPUT_PATH,'temp_indices',db_name)
                                     end 
                       #Error file path
                                     info[db_name]['update_error_file'] = File.join(info[db_name]['index'],'update_stderror_'+db_name+'.txt')                  
                     end
         # STATUS INFO (fastas,size...
               # DB name
                     info[db_name]['name'] = db_name
               # Fastas paths
                     info[db_name]['fastas'] = File.directory?(info[db_name]['path']) ? Dir[File.join(info[db_name]['path'],"*.fasta*")].sort : info[db_name]['path']
               # DB size
                     db_size = info[db_name]['fastas'].map { |file| File.size?(file) }.inject(:+)
                     info[db_name]['size'] = db_size
             end

      end
   #UPDATE INDEX
      def update_index(databases,info)

           # Updating obsolete databases
             databases.each do |db_name| 
           # Test writing permissions
                     if !File.writable?(File.dirname(info[db_name]['index'])) || !File.writable?(File.dirname(info[db_name]['update_error_file']))
                             STDERR.puts("Exiting. Impossible to update database (#{@info['obsolete_databases']}) index because folder: #{File.join(@dir,'indices')} and/or #{File.join(@dir,'status_info')} are not writable. Please contact your admin to update your databases or add -c tag to avoid this step.")
                             exit(-1)
                     end
           # Removing old index,and old stderror. Make new index folder
                     FileUtils.rm_rf(@info[db_name]['index']) if Dir.exist?(@info[db_name]['index'])
                     FileUtils.rm(@info[db_name]['update_error_file']) if File.exist?(@info[db_name]['update_error_file'])
                     Dir.mkdir(@info[db_name]['index'])
           # Info
                     STDERR.puts("Updating #{db_name} database index")
           # Loading BBtools module and cmd execution
                     cmd = @bbtools.load_bbsplit('bbsplit',{'ref' =>  @info[db_name]['path'], 'path' => @info[db_name]['index'], 'in' => nil, 'out' => nil, 'int' => nil})
    cmd << " 2> #{@info[db_name]['update_error_file']}"
    system(cmd)          
  end 

 end

 end