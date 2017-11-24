########################################################
# Defines the main methods that are necessary to filter out low complexity reads
########################################################

class PluginLowComplexity < Plugin

  #Returns an array with the errors due to parameters are missing 
      def check_params
             
       #Priority, base ram
             cores = [1]
             priority = 1
             ram = [50] #mb
       #Array to store errors 
             errors=[]   
       #Check params (errors,param_name,param_class,default_value,comment)
             @params.check_param(errors,'low_complexity_threshold','String',0.001,'Complexity threshold to be applied. Complexity is calculated using the counts of unique short kmers that occur in a window, such that the more unique kmers occur within the window - and the more even the distribution of counts - the closer the value approaches 1. Complexity_threshold = 0.01 for example will only filter homopolymers')

             @params.check_param(errors,'minlength','String',50,'Minimal reads length to be keep')

             @params.check_param(errors,'low_complexity_aditional_params','String',nil,'Aditional BBduk2 parameters for low complexity filtering. Add them together between quotation marks and separated by one space')
       #Set resources
             @params.resource('set_requirements',{ 'plugin' => 'PluginLowComplexity','opts' => {'cores' => cores,'priority' => priority,'ram'=>ram}})
             
             return errors
      end
  #Get options  
      def get_options

           #Opts Array
             opts = Array.new
           #Module options Hash
             module_options = {}
           #Booleans array}
             booleans = []
           #Low complexity filtering params
             module_options['entropy'] = @params.get_param('low_complexity_threshold')
             if @params.get_param('minlength').to_i < 50
                     module_options['entropywindow'] = @params.get_param('minlength')
             else
                     module_options['entropywindow'] = 50
             end
           #TO AVOID A BBDUKs "BUG" discard all reads smaller than entropywindow
             module_options['minlength'] = module_options['entropywindow'].to_i   
           #Adding necessary fragment to save unpaired singles
             module_options['outs'] = File.join(File.expand_path(OUTPUT_PATH),"singles_low_complexity_filtering#{@params.get_param('suffix')}") if @params.get_param('save_unpaired') == 'true'
           #Adding low_complexity aditional params
             booleans << @params.get_param('low_complexity_aditional_params') if !@params.get_param('low_complexity_aditional_params').nil?
           #Adding booleans to module_options
             module_options['booleans'] = booleans if !booleans.empty?
           #Adding commandline redirection
             module_options['redirection'] = ["2>",File.join(File.expand_path(OUTPUT_PATH),'plugins_logs',"low_complexity_stats.txt")]
           #Add hash to array and return
             opts << module_options
             return opts

      end
 #Get cmd
      def get_cmd(result_hash)
           
           #Return  
             return @bbtools.load_bbduk(result_hash['opts'].first)

      end
 #Get stats
      def get_stats(stats_files,stats)

             stats['plugin_low_complexity'] = {} if !stats.key?('plugin_low_complexity')
          # Extracting stats 
             regexp_str = "^Low"
             lines = super(regexp_str,stats_files['cmd'].first)
             stats["plugin_low_complexity"]["low_complexity_discarded_reads"] = lines.first.split(/\t/)[1].split(" ")[0].to_i

      end

end
