#Checks for changes in database and updates index if needed

class CheckDatabase

 def initialize(dir,workers,ram)

  @db_path = File.join(dir,'fastas')
  @cores = Integer(workers)
  @max_ram = ram
  @dir = dir

  # Make indices and status folders
  Dir.mkdir(File.join(dir,'indices')) if !Dir.exists?(File.join(dir,'indices'))
  Dir.mkdir(File.join(dir,'status_info')) if !Dir.exists?(File.join(dir,'status_info'))

  # Checking and updating indices
  update_index

  # Checking for error in indices updating
  test_index

  $LOG.info("Databases indices at #{dir} are updated")

 end

 def update_index

  ignore_folders=['.','..']

  nativelibdir = File.join($BBPATH,'jni')
  classp = File.join($BBPATH,'current')

  $LOG.info("Checking databases indices at #{@db_path} for updates")
 
  dbs_folder=Dir.open(@db_path)

  @updated_databases = Array.new

  # Checking all databases (folders) in DB/fastas
  dbs_folder.entries.each do |db_name|
    
    db_folder=File.join(dbs_folder,db_name)
    db_index=File.join(@dir,'indices',db_name)
    old_status_file = File.join(@dir,'status_info','fastas_'+db_name+'.txt')
    update_error = File.join(@dir,'status_info','update_stderror_'+db_name+'.txt') 
        
  # First condition
    if !ignore_folders.include?(db_name) && File.directory?(db_folder)
        # Loading fastas from database (current files) and from status file (previous update)
        dir_fastas = File.join(db_folder,"*.fasta*")
        current_fastas = Dir[dir_fastas].sort
        old_fastas = File.readlines(old_status_file).map(&:chomp) if File.exists?(old_status_file)
  # Second condition
        if !Dir.exists?(db_index) or !File.exists?(old_status_file) or !current_fastas == old_fastas
  # Third condition
          if File.writable?(File.join(@dir,'indices')) && File.writable?(File.join(@dir,'status_info'))
            # Removing old index and old status file
            FileUtils.rm_rf(db_index) if Dir.exists?(db_index)
            Dir.mkdir(db_index)
            FileUtils.rm(update_error) if File.exists?(update_error)
            FileUtils.rm(old_status_file) if File.exists?(old_status_file)

            # cmd execution
            $LOG.info("Updating #{db_name} database index")

            cmd = "java -Djava.library.path=#{nativelibdir} -ea -Xmx#{@max_ram} -cp #{classp} align2.BBSplitter ow=t fastareadlen=500 t=#{@cores} ref=#{db_folder} path=#{db_index} 2> #{update_error}"

            system(cmd)   

            # writing new status file
            IO.write(old_status_file, current_fastas.join("\n"))
            @updated_databases.push(db_name)

          else
            $LOG.error("Skipping updating #{db_name} index because folder: #{File.join(@dir,'indices')} and/or #{File.join(@dir,'status_info')} are not writable. Please contact your admin to update your databases")
          end   
        end
     end
   end  
 end

 def test_index

  # Test for errors in indexing

  $LOG.info("Checking for errors in databases indices update")

  indexed_databases = File.join(@dir,'status_info','indexed_databases.txt')

  # Load previous test if it exists
  if File.exists?(indexed_databases)
    current_indices = File.readlines(indexed_databases).map(&:chomp)
  else
    current_indices = Array.new
  end
  # Load Warning from previous updates
  all_databases = Dir.open(@db_path)
  all_databases.entries.each do |db_name|
    @updated_databases.push(db_name) if !current_indices.include?(db_name) && !@updated_databases.include?(db_name)
  end

  if @updated_databases.empty?
    return
  end
  # test each database updated
  @updated_databases.each do |db_name|
    
    db_index=File.join(@dir,'indices',db_name)
    stderr=false
    update_error = File.join(@dir,'status_info','update_stderror_'+db_name+'.txt') 
  # first condition
    if Dir.exists?(db_index) and File.exists?(update_error)
      # Open update_error file and look up for errors
      File.open(update_error).each do |line|
       line.chomp!
       if !line.empty?
         if (line =~ /Error/) || (line =~ /Exception in thread/)
           STDERR.puts "Internal error in #{db_name} index update. For more details: #{update_error}. To retry, remove #{db_index} folder"
           current_indices.delete(db_name) if current_indices.include?(db_name)
           stderr=true 
         end
       end
      end 
      current_indices.push(db_name) if !stderr
    end
  end 

 # Writing current indices file
  FileUtils.rm(indexed_databases) if File.exists?(indexed_databases)
  IO.write(indexed_databases, current_indices.join("\n"))

 end

end
