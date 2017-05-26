#Checks for changes in database and updates index if needed

class CheckDatabase

 def initialize(dir,workers,ram)

  @db_path = dir
  @cores = Integer(workers)
  @max_ram = ram

  update_index

  $LOG.info("Databases indexes at #{@db_path} are updated")

 end

 def update_index

  ignore_folders=['.','..','status_info','formatted']
  $LOG.info("Checking databases indexes at #{@db_path} for updates")
 
  dbs_folder=Dir.open(@db_path)
  
  dbs_folder.entries.each do |db_name|
    
    db_folder=File.join(dbs_folder,db_name)
    db_index=File.join(db_folder,'ref')

    if (!ignore_folders.include?(db_name) and File.directory?(db_folder))
 			    
    	new_status_file = File.join(db_folder,'new_fastas_'+db_name+'.txt')
   
    	old_status_file = File.join(db_folder,'old_fastas_'+db_name+'.txt') 
        
        dir_fastas = File.join(db_folder,"*.fasta")
       
        current_fastas = Dir[dir_fastas]
      
        IO.write(new_status_file, current_fastas.join("\n"))
        
        if !Dir.exists?(db_index) or !File.exists?(old_status_file) or !system("diff -q #{new_status_file} #{old_status_file} > /dev/null ")

          FileUtils.rm_rf(db_index) if Dir.exists?(db_index)
          FileUtils.mkdir(db_index)

          $LOG.info("Updating #{db_name} database index")

          puts @cores

          cmd = "bbsplit.sh -Xmx#{@max_ram} t=#{@cores} path=#{db_folder} ref=#{db_folder}"

          system(cmd)      

          system("mv #{new_status_file} #{old_status_file}")

        end
       FileUtils.rm_f(new_status_file)
     end
   end  
 end
end
