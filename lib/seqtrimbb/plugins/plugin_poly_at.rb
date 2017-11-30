  ########################################################
# Defines the main methods that are necessary to trim Poly AT
########################################################

class PluginPolyAt < Plugin
  
  #Returns an array with the errors due to parameters are missing 
      def check_params

       #Priority, base ram
             cores = [1]
             priority = 1
             ram = [50] #mb
       #Array to store errors 
             errors=[]  
       #Check params (errors,param_name,param_class,default_value,comment)
             @params.check_param(errors,'polyat_min_size','Integer',9,'Minimal size of PolyAT')

             @params.check_param(errors,'polyat_aditional_params','String',nil,'Aditional BBduk2 parameters for polyat trimming, add them together between quotation marks and separated by one space')       
       #Set resources
             @params.resource('set_requirements',{ 'plugin' => 'PluginPolyAt','opts' => {'cores' => cores,'priority' => priority,'ram'=>ram}})
             
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
           #Quality's trimming params
             module_options['trimpolya'] = @params.get_param('polyat_min_size')
           #Adding necessary fragment to save unpaired singles
             if @params.get_param('save_unpaired') == 'true'
                     module_options['outs'] = File.join(File.expand_path(OUTPUT_PATH),"singles_polyat_trimming#{@params.get_param('suffix')}")
             end
           # Adding quality aditional params
             booleans << @params.get_param('polyat_aditional_params') if !@params.get_param('polyat_aditional_params').nil?
           # Adding booleans to module_options
             module_options['booleans'] = booleans if !booleans.empty?
           # Adding commandline redirection
             module_options['redirection'] = ["2>",File.join(File.expand_path(OUTPUT_PATH),'plugins_logs',"polyat_trimming_stats.txt")]
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

             stats["plugin_poly_at"] = {} if !stats.key?('plugin_poly_at')
             stats["plugin_poly_at"]["sequences_with_poly_at"] = {} if !stats['plugin_poly_at'].key?('sequences_with_poly_at')
         #Extracting stats 
             regexp_str = "^Poly-A:"
             lines = super(regexp_str,stats_files['cmd'].first)
             splitted_line = lines[0].split(/\t/)
             stats["plugin_poly_at"]["plugin_poly_at"] = splitted_line[1].split(" ")[0].to_i

      end

end
