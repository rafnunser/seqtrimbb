#########################################
# This class provided the methods to build a report
#########################################

class Reporter

	def initialize(json,comparative)
        require 'report'
		# if comparative
		# 	require 'report_comparison.rb'
		# 	@report_data = ReportComparison.new(json)
		# else
			require 'report_sample'
			if json.count > 1
				@report_data = json.map { |jsoni| ReportSample.new(jsoni) }
		    else
		    	@report_data = ReportSample.new(json.first)
		    end
		# end	

	end
    def get_ready       
    	if @report_data.is_a?(Array)
    		@report_data.each { |r_data| r_data.build }
    	else
    		@report_data.build
    	end        
        @report_data.each {|r_data| STDERR.puts r_data.template} if @report_data.is_a?(Array)
    end
	def build_report(output)    	
    	if @report_data.is_a?(Array)
    		@report_data.each do |r_data|
    			call_report_html(r_data,r_data.get_output(output))
    		end
    	else
			call_report_html(@report_data,@report_data.get_output(output))    	
        end       
	end
	def call_report_html(r_data,output_file)	
		report = Report_html.new(r_data.container)
		report.build(r_data.template)
		report.write(output_file)
	end

end   