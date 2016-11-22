require "plugin"

########################################################
# Author: Almudena Bocinos Rioboo                      
# 
# Defines the main methods that are necessary to execute Plugin
# Inherit: Plugin
########################################################

class PluginReadInputBb < Plugin
  
 def get_cmd
    
    file1=@params.get_param("fastq").first
    
    cmd="cat #{file1}"
    
    return cmd
 end
 
  #Returns an array with the errors due to parameters are missing 
  def self.check_params(params)
    errors=[]  
    return errors
  end

end
