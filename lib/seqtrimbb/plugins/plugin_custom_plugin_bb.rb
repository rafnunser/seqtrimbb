require "plugin"

########################################################
# Author: Almudena Bocinos Rioboo                      
# 
# Defines the main methods that are necessary to execute Plugin
# Inherit: Plugin
########################################################

class PluginCustomPluginBb < Plugin
  
 def get_cmd
    
    cmd="grep #{@params.get_param('custom_plugin_bb_param1')}"

    return cmd
 end
 
  #Returns an array with the errors due to parameters are missing 
  def self.check_params(params)
    errors=[]  
    
    comment='Custom param1'
    default_value = 'templates'
    params.check_param(errors,'custom_plugin_bb_param1','String',default_value,comment)
    
    return errors
  end

end
