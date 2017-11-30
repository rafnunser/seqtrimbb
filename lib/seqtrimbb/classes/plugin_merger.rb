#########################################
# This class provided the methods to merge plugins if possible
#########################################

#TODO! Merge middle plugins. Stats paths in merge...
class PluginMerger
  attr_accessor :list

     #Init
      def initialize(plugin_list)
      	
           #Mergeability hash, for each plugin and array of mergeable plugins
             @mergeability = {}
             @mergeability['PluginReadInputBb'] = []
             @mergeability['PluginAdapters'] = ['PluginReadInputBb','PluginSaveResultsBb']
             @mergeability['PluginContaminants'] = ['PluginReadInputBb']
             @mergeability['PluginLowComplexity'] = ['PluginReadInputBb','PluginSaveResultsBb','PluginQuality']
             @mergeability['PluginMatePairs'] = ['PluginReadInputBb','PluginSaveResultsBb']
             @mergeability['PluginPolyAt'] = ['PluginReadInputBb','PluginSaveResultsBb']
             @mergeability['PluginQuality'] = ['PluginReadInputBb','PluginSaveResultsBb','PluginLowComplexity']
             @mergeability['PluginUserFilter'] = ['PluginReadInputBb']
             @mergeability['PluginVectors'] = ['PluginReadInputBb']
             @mergeability['PluginSaveResultsBb'] = []
      	   #Modify mergeability based on params. TODO
      	   #Instance variables (plugin_list,list)
             @plugin_list = plugin_list
             make_list

      end
     #List
      def make_list

      	#Empty list << plugin_list
             @list = Array.new
             @plugin_list.map { |plugin| @list << plugin }
        #Merging input
             @merged_input = ['PluginReadInputBb']
             1.upto(@plugin_list.count - 2) do |i|
                     if @merged_input.map { |merging_p| @mergeability[@plugin_list[i]].include?(merging_p) }.all?
                             @merged_input << @plugin_list[i] 
                     else
                     	       break
                     end
             end         
             @merged_input.map { |merged| @list.delete(merged) }
             @list = [@merged_input.last] + @list
        #Merging output
             @merged_output = ['PluginSaveResultsBb']

             (@plugin_list.count - 2).downto(1) do |i|
                     if @merged_output.map { |merging_p| @mergeability[@plugin_list[i]].include?(merging_p) }.all?
                             @merged_output << @plugin_list[i] 
                     else
                     	       break
                     end
             end   
             @merged_output.map { |merged| @list.delete(merged) }
             @list << @merged_output.last

      end

      def options(result_hash)

        #Merge Input options
             @merged_input.slice(0..-2).each_with_index { |plugin,i| result_hash.dig(@merged_input[i+1],'opts',0).merge!(result_hash.dig(plugin,'opts',0)) { |key,v1,v2| key == 'redirection' ? v1 : v2 } }
        #Merge Output options
             @merged_output.slice(0..-2).each_with_index { |plugin,i| result_hash.dig(@merged_output[i+1],'opts',0).merge!(result_hash.dig(plugin,'opts',0)) { |key,v1,v2| key == 'redirection' ? v1 : v2 } }
      
      end

end