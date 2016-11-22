######################################
# Author: Almudena Bocinos Rioboo
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
    # default_value='PluginLowHighSize,PluginMids,PluginIndeterminations,PluginAbAdapters,PluginContaminants,PluginLinker,PluginVectors,PluginLowQuality'
    #    params.check_param(errors,'plugin_list','String',default_value,comment)
    params.check_param(errors,'plugin_list','PluginList',nil,comment)

    comment='Generate initial stats'
    default_value='true'
    params.check_param(errors,'generate_initial_stats','String',default_value,comment)

    comment='Generate final stats'
    default_value='true'
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


    plugin_manager = PluginManager.new(plugin_list,params) # creates an instance from PluginManager. This must storage the plugins and load it


    if !Dir.exists?(OUTPUT_PATH)
      Dir.mkdir(OUTPUT_PATH)
    end

    # Extract global stats
    if params.get_param('generate_initial_stats').to_s=='true'
      $LOG.info "Calculating initial stats: i.e. FastQC"
      #Launch fastqc
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
    cmd=cmds.join("|")
    $LOG.info("CMD_TO_EXECUTE:\n#{cmd}")
    
    # EXECUTE CMD:
    system(cmd)

    # Extract global stats
    if params.get_param('generate_final_stats').to_s=='true'
      $LOG.info "Calculating final stats: i.e. FastQC"
      #Launch fastqc
    else
      $LOG.info "Skipping calculating final stats phase."
    end

    # save used params to file
    params.save_file(File.join(OUTPUT_PATH,'used_params.txt'))

    $LOG.info 'Closing server'

  end

end # Seqtrim class
