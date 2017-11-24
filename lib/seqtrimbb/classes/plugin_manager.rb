#########################################
# This class provided the methods to manage the execution of the plugins
#########################################

class PluginManager   
  attr_accessor :plugin_names
  attr_accessor :plugin_result
  
  #Stores and load plugins
      def initialize(plugin_list,params,bbtools,databasessupport)

          #Instance variables
             @plugin_names = plugin_list.split(',').reject{|p| ['',' ',nil].include?(p)}
             @params = params
             @bbtools = bbtools
             @stbb_db = databasessupport
          #Load plugins
             load_plugins_from_files(@plugin_names)
          #Init plugins result, and plugins classes
             init_plugins(@plugin_names)     
    
      end
  # Iterates by the plugin_list, and load it
      def load_plugins_from_files(plugin_list)
    
           # the plugin_name changes to file using plugin_name.decamelize    
             plugin_list.each do |plugin_name|
                     require plugin_name.decamelize
             end
    
      end
  #Iterates by the plugin list, and initialize plugins classes
      def init_plugins(plugin_list)

          #Result hash 
             @plugin_result = {}
          #Init plugins
             @plugin_names.each do |plugin_name|         
                     plugin_class = Object.const_get(plugin_name)
                     if !plugin_class.ancestors.include?(Plugin)
                             STDERR.puts plugin_name + ' is not a valid plugin'
                     end
                     @plugin_result[plugin_name] = {}
                     @plugin_result[plugin_name]['obj'] = plugin_class.new(@params,@stbb_db,@bbtools)
             end

      end
  # Checks if the parameters are right for all plugins's execution. Finally return true if all is right or false if isn't 
      def check_plugins_params

             res = true
             @plugin_names.each do |plugin_name|      
                 #Search for errors
                     errors=@plugin_result[plugin_name]['obj'].check_params          
                 #Errors check-point
                     if !errors.empty?
                             STDERR.puts plugin_name+ ' found following errors:'
                             errors.each do |error|
                                     STDERR.puts '   -' + error
                                     res = false
                             end #end each
                     end #end if
             end #end  each
             return res
    
      end  
  # Receives the plugin's list , and create an instance from its respective class (it's that have the same name)
      def execute_plugins
          #Merge plugin list
             if @params.get_param('merge_cmd')
                     require 'plugin_merger'
                     merger = PluginMerger.new(@plugin_names)
                     @plugin_list = merger.list
             else
                     @plugin_list = @plugin_names
             end  
          #Get Plugins options hashes (Plugin_list before merging)
             @plugin_names.each do |plugin_name|         
                   # Get and Add individual plugins cmd
                     @plugin_result[plugin_name]['opts'] = @plugin_result[plugin_name]['obj'].get_options
             end
          #Merge options
             merger.options(@plugin_result) if @params.get_param('merge_cmd')
          #Distribute resources
             @params.resource('distribute_resources',{'list' => @plugin_list, 'result' => @plugin_result})
          #Get Plugins cmds
             @plugin_list.each do |plugin_name|         
                   #  Get and Add individual plugins cmd
                     @plugin_result[plugin_name]['cmd'] = @plugin_result[plugin_name]['obj'].get_cmd(@plugin_result[plugin_name])
             end

      end
  #Pipes plugins cmds
      def pipe!

          # Pipe every plugin, with some exceptions
             piped_cmd = @plugin_list.map { |plugin_name| @plugin_result[plugin_name]['cmd'] }.join (' | ')            
             return piped_cmd

      end
  #Extract plugins stats
      def extract_stats
         
         #Init stats_files hashes
             @plugin_names.each do |plugin_name|
                     @plugin_result[plugin_name]['stats_files'] = {}
                     @plugin_result[plugin_name]['stats_files']['cmd'] = []
                     @plugin_result[plugin_name]['stats_files']['stats'] = []
             end
         #Load Stats files paths in to plugins result hash and check execution errors
             @plugin_list.each do |plugin_name|
                     @plugin_result[plugin_name]['opts'].each do |opt_hash|
                             @plugin_result[plugin_name]['stats_files']['cmd'] << opt_hash['redirection'][1] if opt_hash.key?('redirection')
                             if ['stats','refstats'].map { |stat| opt_hash.key?(stat) }.any?
                                     stat_file = opt_hash.key?('stats') ? opt_hash['stats'] : opt_hash['refstats']
                                     @plugin_result[plugin_name]['stats_files']['stats'] << stat_file
                             end
                     end
                     #CHECK
                     @plugin_result[plugin_name]['obj'].check_execution_errors(@plugin_result[plugin_name]['stats_files']['cmd'])
             end
         #Load stats for merged plugins
             (@plugin_names - @plugin_list).each do |plugin_name|
                     i = @plugin_names.index(plugin_name)
                     plugin_to_overwrite_index = ((i+1).upto(@plugin_names.count).to_a + (i-1).downto(0).to_a).select { |ind| @plugin_list.include?(@plugin_names[ind]) }.first
                     case 
                             when i < plugin_to_overwrite_index
                                     ['cmd','stats'].map { |stat| @plugin_result[plugin_name]['stats_files'][stat] << @plugin_result[@plugin_names[plugin_to_overwrite_index]]['stats_files'][stat].first if !@plugin_result[@plugin_names[plugin_to_overwrite_index]]['stats_files'][stat].empty? }
                             when i > plugin_to_overwrite_index
                                     ['cmd','stats'].map { |stat| @plugin_result[plugin_name]['stats_files'][stat] << @plugin_result[@plugin_names[plugin_to_overwrite_index]]['stats_files'][stat].last if !@plugin_result[@plugin_names[plugin_to_overwrite_index]]['stats_files'][stat].empty? }                     
                     end                       
             end
         #Extract stats for plugin_names
           #Init hash
             stats = {}
           #Call plugins
             @plugin_names.each do |plugin_name|
                     @plugin_result[plugin_name]['obj'].get_stats(@plugin_result[plugin_name]['stats_files'],stats)
             end
           #Set rejected
             stats["sequences"]["rejected"] = stats["sequences"]["input_count"].to_i - stats["sequences"]["output_count"].to_i
         #Return
             return stats

      end
  #Clean up!
      def clean_garbage!

           #Call plugins
             @plugin_names.each do |plugin_name|
                     @plugin_result[plugin_name]['obj'].clean_up  
             end

      end

end
