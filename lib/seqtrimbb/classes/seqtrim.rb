######################################

# This is the main class.
######################################

class Seqtrim

  def self.exit_status
    return @@exit_status
  end

  # First of all, reads the file's parameters, where are the values of all parameters and the 'plugin_list'  that specifies the order of execution from the plugins.
  #
  # Secondly, loads the plugins in a folder .
  #
  # Thirdly, checks if parameter's file have the number of parameters necessary for every plugin that is going to be executed.


  def check_global_params(params)
    errors=[]

    # check plugin list
    comment='Plugins applied to every sequence, separated by commas. Order is important'
    # default_value='PluginAdapters,PluginContaminants,PluginLowQuality'
    #    params.check_param(errors,'plugin_list','String',default_value,comment)
    params.check_param(errors,'plugin_list','PluginList',nil,comment)

    comment='Generate initial stats'
    default_value='false'
    params.check_param(errors,'generate_initial_stats','String',default_value,comment)

    comment='Generate final stats'
    default_value='false'
    params.check_param(errors,'generate_final_stats','String',default_value,comment)

    comment='Seqtrim version'
    default_value=Seqtrimbb::SEQTRIM_VERSION
    params.check_param(errors,'seqtrim_version','String',default_value,comment)

    if !errors.empty?
      $LOG.error 'Please, define the following global parameters in params file:'
      errors.each do |error|
        $LOG.error '   -' + error
      end
    end

    return errors.empty?

  end


  def initialize(options)
    
    @@exit_status=0

    # ,options[:fasta],options[:qual],,,,
    params_path=options[:template]

    workers=options[:workers]

    max_ram=options[:max_ram]

    sample_type=options[:sample_type]

    ext_cmd=options[:ext_cmd]

    $LOG.info "Loading params"
    # Reads the parameter's file
    params = Params.new(params_path,options)

    $LOG.info "Checking global params"
    if !check_global_params(params)
      exit(-1)
    end

    # load plugins

    plugin_list = params.get_param('plugin_list') # puts in plugin_list the plugins's array
    $LOG.info "Loading plugins [#{plugin_list}]"

    # Directories

    if !Dir.exists?(OUTPUT_PATH)
      Dir.mkdir(OUTPUT_PATH)
    end

    if !Dir.exists?(DEFAULT_FINAL_OUTPUT_PATH)
      Dir.mkdir(DEFAULT_FINAL_OUTPUT_PATH)
    end

    if !Dir.exists?(OUTPLUGINSTATS)
      Dir.mkdir(OUTPLUGINSTATS)
    end

    if plugin_list.include?('PluginUserFilter')

       output_filtered = File.join(DEFAULT_FINAL_OUTPUT_PATH,"filtered_files")

       if !Dir.exists?(output_filtered)
         Dir.mkdir(output_filtered)
       end

    end

    # Mate Pairs treatment

    if plugin_list.include?('PluginMatePairs')

      $LOG.info("Initiating: Mate Pairs treatment")

      require 'plugin_mate_pairs.rb'

      pmate_pair = PluginMatePairs.new(params)

      pmate_pair.treat_lmp(params)

      tmplist = plugin_list.split(",")

      tmplist.delete('PluginMatePairs')

      plugin_list = tmplist.join(",")

      outlongmate = File.join(File.expand_path(OUTPUT_PATH),"longmate.fastq.gz")
      outunknown = File.join(File.expand_path(OUTPUT_PATH),"unknown.fastq.gz")
      FileUtils.rm(outlongmate)
      FileUtils.rm(outunknown)

      $LOG.info("Finalizing: Mate Pairs treatment")

    end

    plugin_manager = PluginManager.new(plugin_list,params) # creates an instance from PluginManager. This must storage the plugins and load it

    # Extract global stats
    if params.get_param('generate_initial_stats').to_s=='true'
      $LOG.info "Calculating initial stats: i.e. FastQC"
      
      prefiles = $SAMPLEFILES.join(" ")
      cmd="fastqc -o #{OUTPUT_PATH} #{prefiles}"

      system(cmd)
    else
      $LOG.info "Skipping calculating initial stats phase."
    end

    # load plugin params
    $LOG.info "Check plugin params"
    if !plugin_manager.check_plugins_params(params) then
      $LOG.error "Plugin check failed"

      # save used params to file
      params.save_file(File.join(OUTPUT_PATH,'used_params.txt'))
      exit(-1)
    end

    # EXECUTE PLUGINS:
    cmds = plugin_manager.execute_plugins()

    $LOG.info("Plugin_results=#{cmds.join("\n")}")

    # ADDING A CALL TO MAP OR ASSEMBLE THE SAMPLE (USING AN EXTERNAL TOOL)

    if ext_cmd
      
      cmds.push(ext_cmd)

      $LOG.info("CMD_TO_MAP/ASSEMBLE:\n#{ext_cmd}")

    end

    cmd=cmds.join(" | ")
    $LOG.info("CMD_TO_EXECUTE:\n#{cmd}")
    
    # EXECUTE CMD:

    $LOG.info("Initializing cleaning process...")
    
    system(cmd)

    # Storing all plugins stats

   if tmplist != nil

     plist = params.get_param('plugin_list')

     plugin_manager = PluginManager.new(plist,params)
     
   end 

   stats = plugin_manager.get_plugins_stats()

    # Hash to json and saving json file

   jstats = stats.to_json

   File.open("#{DEFAULT_FINAL_OUTPUT_PATH}/stats.json","w") do |f|
    f.write(JSON.pretty_generate(stats))
   end

   $LOG.info("...Finalizing cleaning process")

    # Extract global stats
    if params.get_param('generate_final_stats').to_s=='true'
      $LOG.info "Calculating final stats: i.e. FastQC"

      postfiles = $OUTPUTFILES.join(" ")
      cmd='fastqc -o #{OUTPUT_PATH} #{postfiles}'

      system(cmd)
    else
      $LOG.info "Skipping calculating final stats phase."
    end

    # save used params to file
    params.save_file(File.join(OUTPUT_PATH,'used_params.txt'))

  end

end # Seqtrim class
