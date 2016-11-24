require "plugin"

########################################################

#
# Defines the main methods that are necessary to execute Plugin
# Inherit: Plugin
########################################################

class PluginCustomPlugin2Bb < Plugin

  def get_cmd

    cmd="grep #{@params.get_param('custom_plugin_2_bb_param2')}"

    return cmd
  end

  #Returns an array with the errors due to parameters are missing
  def self.check_params(params)
    errors=[]

    comment='Custom param2'
    default_value = 'gen'
    params.check_param(errors,'custom_plugin_2_bb_param2','String',default_value,comment)

    return errors
  end

end
