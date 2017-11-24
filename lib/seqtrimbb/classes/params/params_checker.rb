#########################################
# This class provided the methods to check the parameters from a params object
#########################################
 
class ParamsChecker < Params

# Init param check
  def initialize(errors,param,param_class,default_value,comment,ext_object)

         if !exist?(param)
       #if default_value.nil? #|| (default_value.is_a?(String) && default_value.empty?
          #nil_warnings = ['plugin_list']     
          #$LOG.info "#{param} value is nil" if nil_warnings.include?(param)
       #else
               set_param(param,default_value,comment)
       #end   
         end
         s = get_param(param)
         begin
                 case param_class
                         when 'DB'
                        # it is a string
                                 r = String(s)
                        # and must be a valid db
                                 r = check_db_param(param,ext_object)
                         when 'PluginList'
                                 r = String(s)
                                 r = check_plugin_list_param(param)
                         else
             	                   send(param_class,s)
                 end
         rescue StandardError => e
                         message="Current value is ##{s}#. "
                         if param_class =='DB' || param_class == 'PluginList'
                                 message += e.message
                         end
                         errors.push "Param #{param} is not a valid #{param_class}. #{message}"
         end
     # end

  end
#Check if plugins lists param is valid
  def check_plugin_list_param(param_name)

     # get plugin list (raise if nil or empty)
         pl_list = get_param(param_name)
     		 raise ArgumentError.new('PluginList is nil or empty') if (pl_list.nil? || pl_list.empty? || !(pl_list =~ /^\s*$/).nil?)
     # split and strips pl_list (String to Array of strings). The first plugin is always the reader, and last plugin is always the writer
      	 list = ['PluginReadInputBb'] + pl_list.strip.split(',').map!{|e| e.strip}.reject{|p| ['PluginReadInputBb','PluginSaveResultsBb'].include?(p)} + ['PluginSaveResultsBb']
     # checks plugins_names
     		 current_plugins = Dir[File.join(SEQTRIM_PATH,'lib','seqtrimbb','plugins',"*.rb")].map!{|p| File.basename(p,'.rb')} + ['',' ',nil]
      	 list.each do |plugin_name|
         				 if !current_plugins.include?(plugin_name.decamelize)
             						 raise ArgumentError.new("Plugin #{plugin_name} does not exists")
         				 end
     		 end
     # Set updated pluginlist
         set_param(param_name,list.join(','))

  end
#Check if dbs param is valid
  def check_db_param(db_param_name,stbb_db)
    
    #Get databases list and init errors Array
         db_list=get_param(db_param_name)
         errors = []
    #Check is list is valid
         if [nil,'',' '].include?(db_list)
                 errors << "Database #{db_param_name} is empty. Specify a valid database."    
         end
    #First split db_list (internal vs external)
         internal_dbs,external_dbs = db_list.split(',').partition { |d| !File.exist?(d) }
    #For internal databases checks if it is in databases array, installed and updated
         internal_dbs.each do |db|
                 error = stbb_db.check_status(stbb_db.info,db)
                 errors << "Database #{db_param_name} is NOT:\n#{error.join(" and/or ")}" if !error.empty?
         end
    #For external databases SET/MAINTENANCE/CHECK
         if !external_dbs.empty?
                 stbb_db.set_external(external_dbs)
                 stbb_db.maintenance_external(external_dbs)
    #Checks errors
                 external_dbs.each do |db|
                         error = stbb_db.check_status(stbb_db.external_db_info,db)
                         errors << "External satabase #{db_param_name} is NOT:\n#{error.join(" and/or ")}" if !error.empty?
                 end
         end
    #Raise if errors were found
         raise ArgumentError.new(errors.join("\n")) if !errors.empty?
  
  end
 
end