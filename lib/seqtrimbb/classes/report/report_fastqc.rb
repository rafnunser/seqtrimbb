#########################################
# This class provided the methods to build a report
#########################################

class ReportFastqc < Report

	def initialize
		#Load to container
		@@container['fastqc_summary'] = [['sample']]
		@@container['fastqc_images'] = {}

		@@json['fastqc'].each do |time,time_hash|
			time_hash.each do |apt,apt_hash|
				if apt == "summary"
					apt_hash.each do |sumk,sumv|
						if sumk == "head"
							sumv.each { |x| @@container['fastqc_summary'].first << x.gsub('_',' ') if !@@container['fastqc_summary'].first.include?(x.gsub('_',' ')) }
						else
							samplename = sumk == "global" ? "mean #{time}":sumk							
							@@container['fastqc_summary'] << [samplename,sumv].flatten
						end
					end
				else
					apt_hash['images'].each do |imgk,imgv|
						@@container['fastqc_images'][imgk] ||= {}
						@@container['fastqc_images'][imgk][time] ||= {}
						@@container['fastqc_images'][imgk][time][apt] = imgv
					end
				end
			end
		end
	end

	def load_html
		#Load summary table
		report = []
		report << %(			<h3 style="text-align:center;">Summary table</h3>)
		report << %(			<div style="overflow: hidden">)
	 	report << %(				<%=table(id:'fastqc_summary', header:true, attrib:{class:"sample-head-table",style:"font-size:small;"}, border:0)%>)
		report << %(			</div>)
		#Load fastqc images
		report << %(			<h3 style="text-align:center;">Graphs</h3>)
		img_attribs = 'style="max-width:90%; max-height:90%; margin-right:5%; margin-left:5%;"'
		#For each image
		@@container['fastqc_images'].each do |graph,values|
			report << %(			<h4 style="text-align:center;">#{graph}</h4>)
			report << %(			<div style="overflow: hidden" >)
			values.each do |time,samples|
				cwidth = samples.keys.length > 1 ? %(50):%(80)
				report << %(				<p class="sample-head-table-title">#{time}</p>)
				report << %(				<div style="overflow: hidden" class="flex-row">)
				samples.keys.each do |sampk|
					report << %(					<div class="flex-column-#{cwidth}">)
	    			report << %(						<p class="sample-head-table-title">#{sampk}</p>)		
	 				report << %(						<img #{img_attribs} src=\"data:image/png;base64,<%=@hash_vars['fastqc_images']['#{graph}']['#{time}']['#{sampk}']%>\">)
					report << %(					</div>)				
				end	
				report << %(				</div>)
			end
			report << %(			</div>)
		end
		return report
	end

end