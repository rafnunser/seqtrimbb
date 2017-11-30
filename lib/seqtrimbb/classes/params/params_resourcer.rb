#########################################
# This class provided the methods to properly distribute given resources between plugins
#########################################

class ParamsResourcer < Params
      
      def initialize

           #Init hashes
             @plugin_cores = {}
             @plugin_priority = {}
             @plugin_ram = {}
           #Load cores
             @cores = get_param('workers').to_i
 
      end

      def set_requirements(opt_hash)

           #Add plugins requirements 
             @plugin_cores[opt_hash['plugin']] = opt_hash['opts']['cores']
             @plugin_priority[opt_hash['plugin']] = opt_hash['opts']['priority']
             @plugin_ram[opt_hash['plugin']] = opt_hash['opts']['ram']

      end

      def distribute_resources(opt_hash)
             
             final_plugin_list = opt_hash['list']
             result_hash = opt_hash['result']
           #Distribute resources 
             distribute_cores(final_plugin_list)
             distribute_ram(final_plugin_list)
           #Assign to options
             final_plugin_list.each do |plugin|
                     @plugin_cores[plugin].each_with_index do |cores,i|
                             result_hash[plugin]['opts'][i]['t'] = cores
                     end
                     @plugin_ram[plugin].each_with_index do |ram,i|
                             result_hash[plugin]['opts'][i]['ram'] = ["-Xmx#{ram}m"]
                     end
             end

      end 

      def distribute_cores(final_plugin_list)
             
           #Setup priority (list,levels,threshold)
             priority = setup_priority(final_plugin_list,2,[0,2,3])
             surplus_cores = @cores - priority['default_cores'].inject(0,:+)
           #Return if surplus cores <= 0
             if surplus_cores <= 0
                     return
             end
           #IF
             if surplus_cores > 0
                 #Distribute cores            
                     distribute!(surplus_cores,priority)
             end

      end

      def distribute_ram(final_plugin_list)

           #Adds RAM for extra thread
             final_plugin_list.each do |plugin|
                     @plugin_ram[plugin].each_with_index do |ram,i|
                             @plugin_ram[plugin][i] = ram + 70*(@plugin_cores[plugin][i] - 1)
                     end
             end

      end

      def setup_priority(list,levels,levels_threshold)

           #Init Hash and Arrays
             priority = {}
             priority['levels'] = levels
             priority['levels_threshold'] = levels_threshold
             priority['default_cores'] = []
             priority['updated_cores'] = []
             priority['queue'] = []
           #Set priority max level
             (priority['levels'] + 1).times do 
                     priority['default_cores'] << 0
                     priority['updated_cores'] << 0
                     priority['queue'] << Array.new
             end
           #Fills priority
             list.each do |plugin|
                     priority['default_cores'][@plugin_priority[plugin]] += @plugin_cores[plugin].count
                     priority['updated_cores'][@plugin_priority[plugin]] += @plugin_cores[plugin].count
                     priority['queue'][@plugin_priority[plugin]] << plugin
             end
      	     return priority

      end

      def distribute!(resource,priority)
           
           while resource > 0  
           #For i in levels..1
             for i in priority['levels'].downto(1) do
                 #While Updated/default <  Update/default(priority - 1) * threshold. Distribute
                   while (priority['updated_cores'][i].to_f/priority['default_cores'][i].to_f < (priority['updated_cores'][i-1].to_f/priority['default_cores'][i-1].to_f) * priority['levels_threshold'][i].to_f) || (i == 1 && !(priority['updated_cores'][i+1].to_f/priority['default_cores'][i+1].to_f < (priority['updated_cores'][i].to_f/priority['default_cores'][i].to_f) * priority['levels_threshold'][i+1].to_f))     
                          #For every plugin on priority level 
                           priority['queue'][i].each do |plugin|
                           	       return if resource == 0
                           	     #For every call in plugin. ADD 1 CORE
                                   @plugin_cores[plugin].each_with_index do |value,k|
                                             return if resource == 0
                                             @plugin_cores[plugin][k] += 1
             	                               resource -= 1
                                             priority['updated_cores'][i] += 1 
                                   end                          
                           end
                   end
             end
           end

      end

end