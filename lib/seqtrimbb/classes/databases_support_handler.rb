#########################################
# This class provide methods to handle installation, indexing, or updating external and internal databases
#########################################

class DatabasesSupportHandler

	   attr_accessor :info 
	   attr_accessor :external_db_info 
#INIT
	    def initialize(options,dir,bbtools)
             
             require 'databases_support.rb'
  #Instance variables
      #Databases path
             @dir = dir
      #Cores
             @cores = options[:workers]
      #BBtools
             @bbtools = bbtools

	    end
#INTERNAL METHODS
  #INIT 
      def init_internal(options = {})
             
             require 'databases_support_internal.rb'
     #Initialize Internal databases support
             @internal_databases = DatabasesSupportInternal.new(@dir,@info={})
     #Set databases
             @internal_databases.set_databases?(options[:databases_action],options[:databases_list],@info)

      end
  #MAINTENANCE
      def maintenance_internal(options)

          #Build DB structure if it's not present
             @internal_databases.check_structure(@dir)
          #IF it is requested, proceeds to install or reinstall databases
           # if options[:install_db]
                #    require 'databases_support_install.rb'
                #    DatabasesSupportInstall.new(options[:install_db_name])
                #    save_json if save?
                #    exit(-1)
           # end
          #Unless -c option is passed, proceeds to check databases status
             if options[:check_db]
                     @internal_databases.check_databases(@info['databases'],@info,@bbtools)
             else
                    STDERR.puts "Skipping checking and indexing databases step."
             end

      end
  #SAVE?
      def save?

         # True if info has been modified
             return true if @info.key?('modified')

      end

#EXTERNAL METHODS
  #INIT
	    def init_external

  #Initialize external DBs support
             require 'databases_support_external'
          #Init external class and create an external_db_info hash
             @external_databases = DatabasesSupportExternal.new(@external_db_info={})

	    end
  #ADD database
      def set_external(paths_to_dbs)
             
             init_external?
             @external_databases.set_databases?('add',paths_to_dbs,@external_db_info)

      end
  #MAINTENANCE
      def maintenance_external(paths_to_dbs)
            
             @external_databases.check_databases(paths_to_dbs,@external_db_info,@bbtools)

      end
  #TEST if INIT
      def init_external?
     
             if !defined?(@external_databases)
                     init_external
             end

      end

#LIST DATABASES
      def list_databases(list)

             require 'databases_support_list.rb'
             DatabasesSupportList.new(list,@info)

      end

#SAVE JSON
      def save_json(info,file)

             File.open(file,"w") do |f|
                     f.write(JSON.pretty_generate(info.except('modified')))
             end
             
      end

#CHECK ON DATABASE STATUS (INFO LEVEL). Return found errors.
      def check_status(info,database)
                 
                 error = ['installed','indexed'].select { |c| info.key?("#{c}_databases") && !info["#{c}_databases"].include?(database) }
                 error << 'present on internal databases list' if !info['databases'].include?(database)
                 return error

      end

end