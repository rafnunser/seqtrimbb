#########################################
# This class provided the methods to manage the execution of the plugins
 #########################################

require 'json'

class PluginManager   
  attr_accessor :plugin_names
  
  #Storages the necessary plugins specified in 'plugin_list' and start the loading of plugins
  def initialize(plugin_list,params)
    @plugin_names = plugin_list.strip.split(',').map{|p| p.strip}.reject{|p| ['',nil].include?(p)}
    @params = params
    
    # puts plugin_list
    load_plugins_from_files     
    
  end
  
  # Receives the plugin's list , and create an instance from its respective class (it's that have the same name)
  def execute_plugins()

    # $LOG.info " Begin process: Execute plugins "
    cmds=[]

    if !@plugin_names.empty?

      @plugin_names.each do |plugin_name|
          
        # Creates an instance of the respective plugin stored in "plugin_name",and asociate it to the sequence 'seq'
        plugin_class = Object.const_get(plugin_name)
        p = plugin_class.new(@params)
        cmds << p.get_cmd

      end #end  each
      
    else
      raise "Plugin list not found"
    end #end  if lista-param

    return cmds
  end
  
  # Checks if the parameters are right for all plugins's execution. Finally return true if all is right or false if isn't 
  def check_plugins_params(params)
    res = true
    
    if !@plugin_names.empty?
      #$LOG.debug " Check params values #{plugin_list} "

      @plugin_names.each do |plugin_name|
        
        #Call to the respective plugin storaged in 'plugin_name'
        plugin_class = Object.const_get(plugin_name)
        # DONE - chequear si es un plugin de verdad u otra clase
        # puts plugin_class,plugin_class.ancestors.map {|e| puts e,e.class}
        
        if plugin_class.ancestors.include?(Plugin)
          errors=plugin_class.check_params(params)          
        else
          errors= [plugin_name + ' is not a valid plugin']
        end

        if !errors.empty?
          $LOG.error plugin_name+ ' found following errors:'
          errors.each do |error|
            $LOG.error '   -' + error
            res = false
          end #end each
        end #end if

      end #end  each
    else
      $LOG.error "No plugin list provided"
      res = false
    end #end  if plugin-list
    
    return res
  end
  
  
  # Iterates by the files from the folder 'plugins', and load it
  def load_plugins_from_files
    
    # the plugin_name changes to file using plugin_name.decamelize    
    @plugin_names.each do |plugin_name|
      plugin_file = plugin_name.decamelize
      require plugin_file
    end
    
  end

  
end
