
#List all entries in a DB, by name
#
#list all DB names if db is ALL

class ListDb

def initialize(path,db)
  
# if db = 'all' puts available databases
 if db.downcase == 'all'
   puts "Available databases at #{path}"
   puts '-'*2
   list_databases(path)
 else
# if db != all puts fasta files in db. if db exists, if it doesn't puts all available databases
  pre='fastas_'+db+'.txt'
  filename=File.join(path,'status_info','fastas_'+db+'.txt')

  if !File.exists?(filename)
   puts "File #{filename} doesn't exists. Try checking databases first."
   puts ''
   puts "Available databases:"
   puts '-'*2
   list_databases(path)
  else
   puts "Fasta files in #{db} database:"
   puts '-'*2
   f = File.open(filename)	
   f.each do |line|
    fasta_name = File.basename(line)
    puts "      "+fasta_name
   end
   f.close
  end
 end

end

def list_databases(path)

  if File.exists?(File.join(path,'fastas'))
   ignore_folders=['.','..']			
   dbs=Dir.open(File.join(path,'fastas'))
   dbs.entries.each do |db_name|
    if !ignore_folders.include?(db_name)
     puts "      "+db_name
    end
   end
  end

end

end
