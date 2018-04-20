#########################################
# This class provided the methods to build a samples report
#########################################

class ReportSample < Report

	# def initialize(loaded_json)
	#  #Initialize class variables and general header	
	# 	super
	# end

	def build
	 #Add samples general overview
		add_to_template(make_head)
	 #Add Plugins preprocessing info
		add_to_template(make_plugins(@@json.keys.select { |key| key =~ /^plugin/}))
	 #Add Pre/Post FASTQC info
		if @@json.keys.include?("fastqc")
			add_to_template(make_fastqc)
		end
	end

	def make_head
	  #Add info to container
		@@container['general'] = @@json['general'].to_a
		@@container['sequences'] = @@json['sequences'].to_a
	  #	Make a table to show sample's general overview.
		sample_head = []
		sample_head << %(	<h2 style="text-align:center;">Sample general overview</h2>)
		sample_head << %(	<div style="overflow: hidden" class="flex-row">)
		sample_head << %(		<div class="flex-column-50">)
		sample_head << %(			<p class="sample-head-table-title">Input file/s info</p>)
		sample_head << %(			<%=table(id:'general', attrib:{class:"sample-head-table"}, border:0)%>)
		sample_head << %(		</div>)
		sample_head << %(		<div class="flex-column-50">)
		sample_head << %(			<p class="sample-head-table-title">Reads info</p>)	    
		sample_head << %(			<%=table(id:'sequences', attrib:{class:"sample-head-table"}, border:0)%>)
		sample_head << %(		</div>)
		sample_head << %(	</div>)
	  # Return
	  return sample_head.join("\n")
	end

	def make_plugins(used_plugins)
		plugins = []
	  #Header for this section
		plugins << %(	<h2 style="text-align:center;">Cleaning process statistics by plugin</h2>)
	  #Opening div
		plugins << %(	<div style="overflow: hidden;">)
	  #For each plugin call a method inside plugins class
		used_plugins.each do |plugin_name|
			require plugin_name
			plugin_class = Object.const_get(plugin_name.camelize)
			plugin_obj = plugin_class.new({},{},{})
			(plugins << plugin_obj.get_report(@@json,@@container)).flatten!
		end
	  #Closing div
		plugins << %(	</div>)
	  #Return
		return plugins.join("\n")
	end

	def make_fastqc
		fastqc = []
	  #Header for this section
		fastqc << %(	<h2 style="text-align:center;">FASTQC analysis</h2>)
	  #Opening div
		fastqc << %(	<div style="overflow: hidden;">)
	  #Require
		require 'report_fastqc'
	  #INIT!
		fastqc_report = ReportFastqc.new
		(fastqc << fastqc_report.load_html).flatten!
	  #Closing div
		fastqc << %(	</div>)
	  #Return
		return fastqc.join("\n")	
	end

	def get_output(output_folder)
		sample_name = File.basename(@@json['general']['file'].split(" ").first,".*")
		sample_name.sub!(/_(1|2)$/,'') if @@json['general']['type'] == "paired"
		return File.join(output_folder,"#{sample_name}_seqtrimbb_report.html")
	end
end