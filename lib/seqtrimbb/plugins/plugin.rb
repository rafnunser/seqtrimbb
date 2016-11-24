########################################################

#
# Defines the main methods that are necessary to execute a plugin
#
########################################################

class Plugin

  #Loads the plugin's execution whit the sequence "seq"
  def initialize(params)
    @params = params

    if can_execute?
      get_cmd
    end
  end

  def can_execute?
    return true
  end


  #Begins the plugin's execution whit the sequence "seq"
  def get_cmd
    return 'CMD to execute external tool'
  end

  def self.check_param(errors,params,param,param_class,default_value=nil, comment=nil)

    if !params.exists?(param)
      if !default_value.nil?
        params.set_param(param,default_value,comment)
      else
        errors.push "The param #{param} is required and thre is no default value available"
      end
    else
      s = params.get_param(param)
      # check_class=Object.const_get(param_class)
      begin
        case param_class
        when 'Integer'
          r = Integer(s)
        when 'Float'
          r = Float(s)
        when 'String'
          r = String(s)
        end

      rescue
        errors.push " The param #{param} is not a valid #{param_class}: ##{s}#"
      end
    end
  end

  #Returns an array with the errors due to parameters are missing
  def self.check_params(params)
    return []
  end

end
