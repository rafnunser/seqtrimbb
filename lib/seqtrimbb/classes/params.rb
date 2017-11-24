#########################################
# This class provided the methods to read the parameter's file (template) and to create the structure where will be storaged the param's name and the param's value
#########################################

class Params

  #Creates params structure
      def initialize(options,bbtools)

             @@params = {}
             @@comments = {}
             @@plugin_comments = {}
          #Load
             load_params(options,bbtools)

      end
  #Load params from file and from options
      def load_params(options,bbtools)

             require 'params_reader'
          #Initialize Reader subclass
             @params_reader = ParamsReader.new
          #Read template
             @params_reader.read_file(options[:template])
          #Save options
             @params_reader.save_options(options)
          #Process options
             @params_reader.process_params(bbtools)

      end
  #Access to resourcer
      def resource(input_method,opt_hash)
             
             require 'params_resourcer' unless defined?(ParamsResourcer)
             @resourcer = ParamsResourcer.new unless defined?(@resourcer)
             @resourcer.method(input_method).call(opt_hash)

      end
#GETTER/SETTER
  # Sets a parameter
      def set_param(param,value,comment = nil,plugin = nil)
             
             plugin = get_plugin if plugin.nil?
           # Store param in the hash params
             @@params[param] = value
           # Store comment
             if get_comment(plugin,param).nil?
                     set_comment(plugin,param,comment)
             end

      end

    # Returns true if exists the parameter and false if not
      def exist?(param_name)

             return @@params.key?(param_name)
 
      end
  # Returns the parameter's list in an array
      def get_param(param)

             return @@params[param]

      end
  # Checks param calling to checker class
      def check_param(errors,param,param_class,default_value=nil, comment=nil,ext_object=nil)
  
            require 'params_checker' unless defined?(ParamsChecker)          
            ParamsChecker.new(errors,param,param_class,default_value,comment,ext_object)

      end
  #Overwrites a param. Pass a string "PARAM=VALUE"
      def overwrite_param(param)

          param =~ /^\s*([^=]*)\s*=*\s*(.*)\s*$/
          set_param($1,$2,nil,'Overwrited')

      end
  #Delete param
      def delete_param(param)

             @@params.delete(param)

      end
  # Gets plugin
      def get_plugin

             at = caller(2)[3]
             if /^(.+?):(\d+)(?::in `(.*)')?/ =~ at
                     file = Regexp.last_match[1]
                     plugin=File.basename(file,File.extname(file))
                     if !Dir[File.join(SEQTRIM_PATH,'lib','seqtrimbb','plugins',"*.rb")].map!{|p| File.basename(p,'.rb')}.include?(plugin)
                             plugin='General'
                     end
             end
             return plugin  

      end
# COMMENTS METHODS
  # Get comment
      def get_comment(plugin,param)

             res = nil
             if @@plugin_comments.key?(plugin) && @@plugin_comments[plugin].key?(param)
                     res = @@plugin_comments[plugin][param]
             end
             return res

      end  
  # Set comment
      def set_comment(plugin,param,comment)

          # Init plugins comments
             @@plugin_comments[plugin]={} if !@@plugin_comments.key?(plugin)
          #
             if !comment.is_a?(Array) && !comment.nil?
                     comment = comment.split("\n").compact.map{|l| l.strip}
             end
          # set comment
             @@plugin_comments[plugin][param] = (comment || ['-'])

      end
#OUT METHODS
  # Save param's file
      def save_file(path_file)

             f=File.open(path_file,'w')
             @@plugin_comments.keys.sort.reverse.each do |plugin_name|
                     f.puts "#"*50 + "\n" + "# " + plugin_name + "#"*50 + "\n"
                     @@plugin_comments[plugin_name].keys.each do |param|
                             comment=get_comment(plugin_name,param)
                             f.puts comment.map{|c| '# '+c}
                             f.puts "\n#{param} = #{@params[param]}\n"
                     end
             end
             f.close

      end# end def
  #  Prints the pair name/numeric-value for every parameter
      def print_parameters()

             @@params.each do |key, value|
                     puts "#{key} = #{value} "
             end

      end
  # Prints comments
      def print_comments()

             @@plugin_comments.each do |key, value|
                     puts "#{key}"
                     puts "#{value} "
             end

      end

end
