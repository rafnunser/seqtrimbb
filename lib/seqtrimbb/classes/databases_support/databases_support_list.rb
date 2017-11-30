#########################################
# This class provide shared methods to list databases
#########################################
class DatabasesSupportList < DatabasesSupport

  #LIST databases ids or databases
      def initialize(list,info)

        #Dir
             dir = info['dir']
        #Load all installed databases
             all_databases = Dir[File.join(dir,'fastas',"*")].select { |d|  (File.directory?(d) && ![".",".."].include?(d)) }.map { |d| File.basename(d) }
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
                                     puts "Installed databases: databases at #{dir}"
                                     puts "-"
                                     all_databases.sort.map { |d| puts d }
                                     puts ""
                                     puts "Databases provided by SeqTrimBB:"
                                     puts "-"
                                     @@provided_databases.sort.map { |d| puts d }
                                     puts ""
                                     puts "Indexed databases:"
                                     puts "-"
                                     info['indexed_databases'].sort.map { |d| puts d } if (info.key?('indexed_databases') && !info['indexed_databases'].empty?)
                                     puts "---"
                           else
                                     puts "Entries at #{db_name} database:"
                                     puts "-"
                                     if info.key?(db_name)
                                             info[db_name]['fastas'].map { |f| puts File.basename(f) }
                                     else
                                             Dir[File.join(dir,'fastas',db_name,"*.fasta*")].sort.map { |f| puts File.basename(f) }
                                     end
                                     puts ""                        
                     end

             end

      end
end