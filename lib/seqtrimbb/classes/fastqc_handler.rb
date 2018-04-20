#########################################
# This class provided the methods to manage to execute FASTQC
#########################################

class Fastqc

	def initialize(files_array,cores,output_path)
		@files_array = files_array
		@output_path = output_path
	  #make output path	
    	Dir.mkdir(output_path) if !Dir.exist?(output_path)
      #execute!
    	system("fastqc -q -o #{output_path} -t #{cores} #{@files_array.join(" ")}")
	end

	def load_stats
		require 'zip'
		require 'base64'	  		
		#hash
		data = {}
		data['summary'] = {}
		header = %w{total_sequences read_max_length read_min_length %gc mean_qual_per_base min_qual_per_base_in_lower_quartile min_qual_per_base_in_10th_decile weigthed_qual_per_sequence mean_indeterminations_per_base weigthed_read_length}		
		data['summary']['head'] = header
		#Load data for each file
		@files_array.each do |file|
			filename = File.basename(file).sub(/\Wfastq(\Wgz)?/,'')
			data[filename] = {}
			data[filename]['raw'] = {}			
			#Load Raw data
			open_zipfile = Zip::File.new(File.join(@output_path,"#{filename}_fastqc.zip"))
            last_module = nil
            mod = []
            head = nil			
			open_zipfile.read(File.join("#{filename}_fastqc","fastqc_data.txt")).each_line do |line|
				line.chomp!
        		next if line.include?('NaN')
        		fields = line.split("\t")
        		if fields.first == ">>END_MODULE"
           	 		data[filename]['raw'][last_module] = {}
           	 		data[filename]['raw'][last_module]['head'] = head
           	 		data[filename]['raw'][last_module]['data'] = mod
            		last_module = nil
            		head = nil
            		mod = []
        		elsif fields.first == "##FastQC"
            		next
        		elsif fields.first =~ /^>>/
            		last_module = fields.first.gsub('>>', '')
        		elsif fields.first =~ /^#\w/
        			head = fields.map { |f| f.sub('#','') }
        		else
            		mod << fields
        		end				
			end
			#Load Images
			data[filename]['images'] = {}
			%w{adapter_content duplication_levels per_base_n_content per_base_quality per_base_sequence_content per_sequence_gc_content per_sequence_quality sequence_length_distribution}.each do |image|
				data[filename]['images'][image] = Base64.encode64(open_zipfile.read(File.join("#{filename}_fastqc","Images","#{image}.png")))
			end		
		end
		#Load Mean values!
		data.keys.reject { |x| x =~ /^summary/ }.each do |filename|
			stats_data = []
			#BASIC
			get_basics_stats(stats_data,data[filename])
    		#QUALITY
    		get_quality_means(stats_data,data[filename])
    		#Mean Ns per base
    		stats_data << data[filename]['raw']['Per base N content']['data'].map { |meas| meas[1].to_f }.flatten.reduce([ 0.0, 0 ]) { |(s, c), e| [ s + e, c + 1 ] }.reduce(:/)
    		#Size (weighted mean)
    		stats_data << data[filename]['raw']['Sequence Length Distribution']['data'].map { |meas| meas[0..1] }.reduce([ 0.0, 0 ]) { |(s, c), e| [ s + (e.first.split('-').map(&:to_f).reduce([ 0.0, 0 ]) { |(s, c), e| [ s + e, c + 1 ] }.reduce(:/) * e.last.to_f), c + e.last.to_f ] }.reduce(:/)
			#Add to data
			data['summary'][filename] = stats_data.map(&:to_f)
		end
		#Load Global mean values!
		data['summary']['global'] = data['summary'].keys.reject { |x| x =~ /^head/ }.map { |fname| data['summary'][fname] }.transpose.map { |meas| meas.map(&:to_f).reduce([ 0.0, 0 ]) { |(s, c), e| [ s + e, c + 1 ] }.reduce(:/) }
		data['summary'].keys.select { |x| x != "head" }.each do |key|
			data['summary'][key].map! { |x| x.round }
		end
		return data
	end
	#Get basics
	def get_basics_stats(stats_data,data)
		#Total seqs
    	stats_data << data['raw']['Basic Statistics']['data'].select { |meas| meas[0].to_s =~ /^Total Sequences/ }.flatten[1]
    	#Seq length
    	seq_length = data['raw']['Basic Statistics']['data'].select { |meas| meas[0].to_s =~ /^Sequence length/ }.flatten[1]
		if seq_length.include?('-')
	        min, max = seq_length.split('-')

		else
			min, max = [seq_length]*2
		end
        stats_data << max.to_i
	    stats_data << min.to_i
    	#%GC
    	stats_data << data['raw']['Basic Statistics']['data'].select { |meas| meas[0].to_s =~ /^%GC/ }.flatten[1]
	end
	#Get quality means
	def get_quality_means(stats_data,data)
		#mean quality per base
    	stats_data << data['raw']['Per base sequence quality']['data'].map { |meas| meas[2].to_f }.flatten.reduce([ 0.0, 0 ]) { |(s, c), e| [ s + e, c + 1 ] }.reduce(:/)
    	#min quality per base lower quartile
        stats_data << data['raw']['Per base sequence quality']['data'].map { |meas| meas[3].to_f }.flatten.min
    	#min quality per base 10th
        stats_data << data['raw']['Per base sequence quality']['data'].map { |meas| meas[5].to_f }.flatten.min
        #weighted mean
    	stats_data << data['raw']['Per sequence quality scores']['data'].map { |meas| meas[0..1].map(&:to_f) }.reduce([ 0.0, 0 ]) { |(s, c), e| [ s + e.inject(:*), c + e.last ] }.reduce(:/)
	end

end