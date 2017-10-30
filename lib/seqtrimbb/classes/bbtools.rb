########################################################

#
# Defines the methods that are necessary to load a BBtools module
#
########################################################

class BBtools

# First load modules opening
 def initialize
  # BBTools dirs
  classp
  nativelibdir

  @bbtools = {}
  # Store them in a hash
 	@bbtools['modules'] = {}
 	@bbtools['modules']['reformat'] = "java -ea -cp #{$GLOBAL_PARAMS['BBPATH']['classp']} jgi.ReformatReads}"
 	@bbtools['modules']['bbduk'] = "java -Djava.library.path=#{$GLOBAL_PARAMS['BBPATH']['nativelibdir']} -ea -cp #{$GLOBAL_PARAMS['BBPATH']['classp']} jgi.BBDukF"
  @bbtools['modules']['bbsplit'] = "java -Djava.library.path=#{$GLOBAL_PARAMS['BBPATH']['nativelibdir']} -ea -cp #{$GLOBAL_PARAMS['BBPATH']['classp']} align2.BBSplitter ow=t fastareadlen=500 minhits=1 maxindel=20 qtrim=rl untrim=t trimq=6"
  @bbtools['modules']['splitnextera'] = "java -ea -cp #{classp} jgi.SplitNexteraLMP"
  @bbtools['modules']['testformat'] = "java -ea -cp #{$GLOBAL_PARAMS['BBPATH']['classp']} fileIO.FileFormat"
 end

# Load a BBtools module with specific options (from plugins)
 def load_module(module_bb,module_options)
	# Preload default options and calls invariable fragment
    cmd = []
    cmd << get_module(module_bb)
    # Merging default options (from global params) and module options
    options = $GLOBAL_PARAMS['default_options'].merge(module_options)    
    # Building cmd
    cmd << concatenate_options(options)
    # Return loaded cmd
    return cmd.join(" ")
 end

 # Execute a BBtools module with specific options and returns cmd output
 def execute_module(module_bb,module_options)
 	# Load module
    cmd = load_module(module_bb,module_options)
  # Execute module
    return %x[#{cmd}]
 end

 def get_module(module_bb)
    return @bbtools['modules'][module_bb]
 end

# Load specific options in to the module
 def concatenate_options(options)
     cmd = []
     options.each do |opt,arg|
      if !arg.is_a?(Array) && !arg.nil?
         cmd << "#{opt}=#{arg}"
      elsif arg.is_a?(Array) && !arg.empty?
         cmd << arg.compact.join(" ")
      end
     end
     return cmd
 end

# Store default options
def store_default(options)
   @default_options = options
end

# Load db info for a specific module
 def load_db_info(module_bb,db)
  # First select BBtools module
    case module_bb
   # BBsplits databases loading
    when 'bbsplit'
        # If db exists is external
        if File.exist?(db)
        # Extract info
           db_update = CheckDatabaseExternal.new(db)
           db_info = db_update.info
        # If doesn't is internal
        else
           db_update = CheckDatabase.new($DB_PATH)
           db_info = db_update.info[db]
        end
        # List avalaible files in db
        db_list = {}
        if File.file?(db)
        # Single-file database
          db_list[File.basename(db,".*").split("_")[0..1].join(' ')] = db
          db_info['list'] = db_list
        else  
        # Multiple file database
        #Fill the array with the species presents in the external database
         db_info['fastas'].each do |line|
          line.chomp!
          species = File.basename(line).split(".")[0].split("_")[0..1].join(" ") # al basename añadir la finalizacion del archivo como arriba
          db_list[species] = line
         end 
    
         db_info['list'] = db_list
        end
   # BBduks databases loading
    when 'bbduk'
       # Creates hash to store db info
        db_info = {}
       # if db exits is external
        if File.exist?(db)
          # Single-file database
           if File.file?(db)
              fastas = db
          # Folder (multiple-file) database
           else
              fastas = File.join(db,'*.fasta*')
           end
       # if doesn't is internal
        else
              fastas = File.join($DB_PATH,'fastas',db,'*.fasta*')
        end
       # Store paths
        bbduk_db = Dir[fastas].join(',')
        db_info['db_fastas'] = fastas
        db_info['bbduk_db'] = bbduk_db
    end
   # Return db_info
    return db_info
 end

end