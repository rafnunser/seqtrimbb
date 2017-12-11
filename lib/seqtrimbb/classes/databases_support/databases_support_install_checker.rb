#########################################
# This class provide shared methods to check provided databases installation
#########################################

class DatabasesSupportInstallChecker

   #CHECK INSTALLATION
      def self.check_installation(dir,databases)

             installed_dbs = databases.select { |d| (Dir.exist?(File.join(dir,'fastas',d)) || !Dir[File.join(dir,'fastas',d,"*.fasta*")].empty?) }
             return installed_dbs

      end
   #CHECK UPDATE (TODO for EXTERNAL SOURCE)
      def self.check_update(dir,databases)

             updated_dbs = []
             svn_call = 'svn ls --xml https://github.com/rafnunser/seqtrimbb-databases/trunk/'
             ls_call = "ls --full-time #{dir}/fastas"
             repo_databases_info = parse_xml(svn_call)
             local_databases_info = parse_ls(ls_call)
             repo_databases_info.keys.map { |db| updated_dbs << db if (!local_databases_info.key?(db) || repo_databases_info.dig(db) <= local_databases_info.dig(db)) && databases.include?(db) }
             #check files
             updated_dbs.reject! { |db| !self.get_obsolete_files(db,dir).empty? }
             return updated_dbs
             
      end
   #Get obsolete files!
      def self.get_obsolete_files(database,dir)
          
             obsolete_files = []
             svn_call = "svn ls --xml https://github.com/rafnunser/seqtrimbb-databases/trunk/#{database}"
             ls_call = "ls --full-time #{dir}/fastas/#{database}"
             repo_database_info = parse_xml(svn_call)
             local_database_info = parse_ls(ls_call)
             repo_database_info.keys.map { |entry| obsolete_files << entry if !local_database_info.key?(entry) || repo_database_info.dig(entry) > local_database_info.dig(entry) }
             return obsolete_files

      end
   #PARSE XML from SVN ls
      def self.parse_xml(call_from_svn)
             
             begin
             	       svn_xml = IO.popen(call_from_svn)
             rescue Exception => e
                     STDERR.puts "ERROR. Subversion failed:\n #{e}"
                     exit(-1)
             end
             svn_out = svn_xml.read
             result = {}
             svn_out.split(/\n/).select { |l| l =~ (/name|date/) }.each_slice(2) do |entry,date|
                     result[entry.gsub(/<.?name>/,'')] = date.gsub(/<.?date>|-|:|T|Z/,'').to_i
             end
             svn_xml.close
             return result

      end
   #PARSE ls from system
      def self.parse_ls(call_from_system)

             begin
             	       ls_call = IO.popen(call_from_system)
             rescue Exception => e
                     STDERR.puts "ERROR. Ls:\n #{e}"
                     exit(-1)
             end
             ls_out = ls_call.readlines.map(&:chomp).drop(1)
             result = {}           
             ls_out.map! { |line| line.split(/\s+/).drop(5) }.each do |array|
                     result[array.last] = array.take(2).join('').gsub(/-|:/,'').to_i
             end
             ls_call.close
             return result

      end

end