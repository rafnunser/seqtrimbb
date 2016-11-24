require "plugin"

########################################################
# 
# Defines the main methods that are necessary to execute Plugin
# Inherit: Plugin
########################################################

class PluginSaveResultsBb < Plugin
  
 def get_cmd
    
    if @params.get_param('save_results_bb_save_in_gzip')=='true'
      cmd=" gzip > #{File.join(OUTPUT_PATH,'salida.txt.gz')}"
    else
      #without compression
      cmd=" cat > #{File.join(OUTPUT_PATH,'salida.txt')}"
    end

    return cmd
 end
 
  #Returns an array with the errors due to parameters are missing 
  def self.check_params(params)
    errors=[]  
    
    comment='Save results in a compressed file'
    default_value = 'true'
    params.check_param(errors,'save_results_bb_save_in_gzip','String',default_value,comment)
    
    return errors
  end

end
