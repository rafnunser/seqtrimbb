#########################################
# This class provide methods to install databases
#########################################
require 'databases_support_install_checker.rb'

class DatabasesSupportInstall < DatabasesSupport
     
     attr_accessor :installed_databases
      
      def initialize;end
  #INSTALL DATABASES
      def install(databases,info)
        
             databases_list = databases.is_a?(Array) ? databases : databases.split(/ |,/)
         #Add STBBs provided databases if list is empty. Avoid reinstalling databases.
             if databases_list.empty? && !@@provided_databases.empty?
                     previously_installed = DatabasesSupportInstallChecker.check_installation(info['dir'],@@provided_databases)
                     databases_list = @@provided_databases - previously_installed
                     previously_installed.each do |database|
                             databases_list << database if !DatabasesSupportInstallChecker.get_obsolete_files(database,info['dir']).empty?                   
                     end 
                  #Exit if it is still empty
                     if databases_list.empty?
                             STDERR.puts "All databases are installed."
                             return
                     end   
             end
         #Checks writing permissions
             if !File.writable?(File.join(info['dir'],'fastas'))
                     STDERR.puts "ERROR. Writing permissions error, unable to install databases at: #{File.join(info['dir'],'fastas')}"
                     return
             end
         #Checks dbs origin
             databases_list.each_with_index do |database,i|
                     STDERR.puts "Installing database #{database} at: #{File.join(info['dir'],'fastas')}"
         #Remove databases files to reinstall it, if it's installed
                     if @@provided_databases.include?(database)
         #Checks connection
                                     if !connected_to_internet?
                                             STDERR.puts "ERROR. No internet connection. Failed to install database #{database}"
                                             return
                                     end
         #if they're provided by STBB, download it, unpack it, and add it to obsolete databases
                                     reinstall_check(database,info)
                                     download_and_unpack(database,info)
         #if they're an external source, copy (only fasta files), and add it to obsolete databases
                     elsif File.exist?(database)
                                     reinstall_check(File.basename(database).gsub(/\Wfasta(\Wgz)?/,''),info)
                                     copy_and_place(database,info)
                                     databases_list[i] = File.basename(database).gsub(/\Wfasta(\Wgz)?/,'')
                     else 
                             STDERR.puts "ERROR. Database #{database} doesn't exists."
                             databases_list.delete(database)
                     end
             end
         #Checks if they're properly installed
             installation_status = check_installation_status(info['dir'],databases_list)
             STDERR.puts "Completed installation of databases:\n #{installation_status['installed'].join("\n\s")}" if !installation_status['installed'].empty?
             STDERR.puts "ERROR. Failed to install databases:\n #{installation_status['failed'].join("\n\s")}\nYou can retry failed databases installation with -i failed databases list (comma separated)" if !installation_status['failed'].empty?
             STDERR.puts "ERROR. The following databases are missing one or more files:\n #{installation_status['obsolete'].join("\n\s")}\nYou can reinstall the whole database, or use -i update option to retrieve the missing files" if !installation_status['obsolete'].empty?
         #Add installed to info
             installation_status['installed'].map { |d| info['installed_databases'] << d if !info['installed_databases'].include?(d) }
         #Modified?
             info['modified'] = true if !installation_status['installed'].empty?

      end
 #UPDATE!
      def update(info)

         #Checks connection
             if !connected_to_internet?
                     STDERR.puts "ERROR. No internet connection. Unable to update databases"
                     return
             end         
         #Launch update!
             installation_status = check_installation_status(info['dir'],@@provided_databases)
             if installation_status['obsolete'].empty?
                     STDERR.puts "All Databases are updated."
                     return                     
             end
         #Checks writing permissions
             if !File.writable?(File.join(info['dir'],'fastas'))
                     STDERR.puts "ERROR. Writing permissions error, unable to update databases at: #{File.join(info['dir'],'fastas')}"
                     return
             end
         #Update obsolete databases
             installation_status['obsolete'].each do |db|
                     STDERR.puts "Updating database #{db}"
                     update_database(db,info)
             end
         #Update status
             updated = DatabasesSupportInstallChecker.check_update(info['dir'],installation_status['obsolete'])
             failed_to_update = installation_status['obsolete'] - updated
             if !failed_to_update.empty?
                     STDERR.puts "ERROR. Unable to update databases:\n#{failed_to_update.join("\n")}"
             end

      end
     #Checks previous databases installation
      def reinstall_check(database,info)

           # Delete folder from Databases fastas directory and delete old database info
             if Dir.exist?(File.join(info['dir'],'fastas',database))
                     STDERR.puts "A previous installation of database #{database} has been detected. Reinstalling..."
                     FileUtils.rm_rf(File.join(info['dir'],'fastas',database)) 
             end
             info.delete(database) if info.key?(database)
      
      end
     #Download database
      def download_and_unpack(database,info)

          #Download database. From google drive temporary, Hash to store databases Google Drives IDs
             dir_out = File.join(info['dir'],'fastas',database)
             url = "https://github.com/rafnunser/seqtrimbb-databases/trunk/#{database}"
             download_cmd = "svn export #{url} #{dir_out}"
             STDERR.puts "Downloading database: #{database}"
             system(download_cmd)
             if !check_download(info['dir'],database)
                     STDERR.puts "Failed to download database #{database}. Retrying missing files."             
                     update_database(database,info)
             else
                     STDERR.puts "Database #{database} downloaded"
             end

      end
     #Copy database
      def copy_and_place(database,info)
             
          #Databases name, files and checkpoints
             db_name = File.basename(database).gsub(/\Wfasta(\Wgz)?/,'')
          # File or directory. For file, checks if it is a fasta file
             if File.directory?(database)
                     db_files = Dir[File.join(database,"*.fasta*")]
             elsif File.file?(database) && File.basename(database) =~ /^\w*\Wfasta(\Wgz)?/
                     db_files = database
             end
          #Make database directory
             Dir.mkdir(File.join(info['dir'],'fastas',db_name))
          #Copy all fasta files in path
             FileUtils.cp db_files, File.join(info['dir'],'fastas',db_name)

      end
     #Update databases!
      def update_database(database,info)

             obsolete_files = DatabasesSupportInstallChecker.get_obsolete_files(database,info['dir'])
             STDERR.puts "Missing or obsolete files:\n#{obsolete_files.join("\n")}"
             url = "https://github.com/rafnunser/seqtrimbb-databases/trunk/#{database}"
             obsolete_files.each do |file|
                     download_file(url,info['dir'],database,file)
                     if !check_download(info['dir'],database)
                             counter = 1
                             while !check_download(info['dir'],database) && counter <= 10
                                     STDERR.puts "Failed to download file #{file} from database #{database}"
                                     STDERR.puts "Retry #{counter}"
                                     download_file(url,info['dir'],database,file)
                                     counter += 1
                             end
                     end
             end
         
      end
     #Download single file...
      def download_file(url,dir,database,file)

             out = File.join(dir,'fastas',database,file)
             FileUtils.rm(out) if File.exist?(out)
             system("svn export #{url}/#{file} #{out}")             
      
      end
     #Check download
      def check_download(dir,database)
 
             failed_downloads = Dir[File.join(dir,'fastas',database,"svn-*")]
             if failed_downloads.empty?
                     return true
             else 
                     FileUtils.rm(failed_downloads)
                     return false
             end

      end

end