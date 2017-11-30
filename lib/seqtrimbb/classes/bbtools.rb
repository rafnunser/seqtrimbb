########################################################
# Defines the methods that are necessary to load a BBtools module
########################################################

class BBtools

#INIT
       def initialize(dir)

             #BBTools dirs
               classp = File.join(dir,'current')
               nativelibdir = File.join(dir,'jni')
             #Store modules in a hash
 	             @modules = {}
 	             @modules['reformat'] = "java -ea -cp #{classp} jgi.ReformatReads"
 	             @modules['bbduk'] = "java -Djava.library.path=#{nativelibdir} -ea -cp #{classp} jgi.BBDukF"
               @modules['bbsplit'] = "java -Djava.library.path=#{nativelibdir} -ea -cp #{classp} align2.BBSplitter ow=t fastareadlen=500 minhits=1 maxindel=20 qtrim=rl untrim=t trimq=6"
               @modules['splitnextera'] = "java -ea -cp #{classp} jgi.SplitNexteraLMP"
               @modules['testformat'] = "java -ea -cp #{classp} fileIO.FileFormat"
             #Default options
               @default_options = {'in' => 'stdin.fastq', 'out' => 'stdout.fastq', 'int' => 't'}
             #Define modules
               load_modules

       end
#DEFINE METHODS to load a BBtools module with specific options (from plugins)
       def load_modules

             #For each key in @modules hash define a method
               @modules.keys.each do |module_bb|
                     #LOAD
                       define_singleton_method("load_#{module_bb}") do |module_options|
                             #Preload default options and calls invariable fragment
                               cmd = []
                               cmd << get_module(module_bb)
                             #Build cmd with merged options
                               cmd << concatenate_options(@default_options.merge(module_options))
                             #Return loaded cmd
                               return cmd.join(" ")
                       end
               end    

       end
#Get module
       def get_module(module_bb)

               return @modules[module_bb]

       end
#Load specific options in to the module
       def concatenate_options(options)
 
               cmd = []
               redirection = options.delete('redirection') if options.key?('redirection')
               options.each do |opt,arg|
                       if !arg.is_a?(Array) && !arg.nil?
                               cmd << "#{opt}=#{arg}"
                       elsif arg.is_a?(Array) && !arg.empty?
                               cmd << arg.compact.join(" ")
                       end       
               end
               cmd << redirection if defined?(redirection)
             #Return concatenate options string
               return cmd

       end
#Store default options
       def store_default(options)

               @default_options = options

       end
#Merge default options
       def merge_default(options)

               @default_options.merge!(options)
       end

end