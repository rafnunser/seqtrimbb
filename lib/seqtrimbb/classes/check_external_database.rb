class CheckDatabaseExternal

 def initialize(dir,workers,ram)

  @db_path = dir
  @cores = Integer(workers)
  @max_ram = ram

  update_index

 end

 def update_index
 
  db_folder= @db_path

  db_index=File.join(db_folder,'ref')
 			    
  new_status_file = File.join(db_folder,'new_fastas.txt')
   
  old_status_file = File.join(db_folder,'old_fastas.txt') 
        
  dir_fastas = File.join(db_folder,"*.fasta")
       
  current_fastas = Dir[dir_fastas]
      
  IO.write(new_status_file, current_fastas.join("\n"))
        
  if !Dir.exists?(db_index) or !File.exists?(old_status_file) or !system("diff -q #{new_status_file} #{old_status_file} > /dev/null ")

          FileUtils.rm_rf(db_index) if Dir.exists?(db_index)
          FileUtils.mkdir(db_index)

          $LOG.info("Updating #{db_folder} external database index")

          cmd = "bbsplit.sh -Xmx#{@max_ram} t=#{@cores} path=#{db_folder} ref=#{db_folder}"

          system(cmd)      

          system("mv #{new_status_file} #{old_status_file}")

          FileUtils.rm_f(new_status_file)

  end     
 end  
end
