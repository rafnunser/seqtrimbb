
#List all entries in a DB, by name
#
#list all DB names if db is ALL

class ListDb

def initialize(path,db)
  
 pre=['old_fastas_',db,'.txt']
 prejoin=pre.join("")
 filename=File.join(path,db,prejoin)

 if !File.exists?(filename)

  puts "File #{filename} doesn't exists"
  puts ''
  puts "Available databases:"
  puts '-'*2
  
  ignore_folders=['.','..','status_info','formatted']			
  dbs=Dir.open(path)
  
  dbs.entries.each do |db_name|
   if !ignore_folders.include?(db_name)
    puts "      "+db_name
   end
  end	  

 else

  f = File.open(filename)
  		
  f.each do |line|
    
    splitted_line = line.split("/")
    fasta_name = splitted_line.last
    puts "      "+fasta_name

  end
  f.close

 end

end

def self.list_databases(path)

  if File.exists?(path)
   ignore_folders=['.','..','status_info','formatted']			
   dbs=Dir.open(path)
   dbs.entries.each do |db_name|
    if !ignore_folders.include?(db_name)
     puts "      "+db_name
    end
   end
  end

end

end
