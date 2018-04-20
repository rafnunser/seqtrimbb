#########################################
# This class provided the methods to build a report
#########################################

class Report

	def container
    	@@container ||= {}
	end
	def template
		@@template ||= ""
		%(<div style="width:90%; background-color:#f7f9f9; margin:0 auto;">\n) + @@template + %(<br>\n</div>)		
	end

	def initialize(json)
		@@json = json		
		@@template = ''
		@@container = {}
		#Load Header of html output
		head_html = []
		head_html << %(<style type="text/css">)
		head_html << %(	.sample-head-table {padding: 8px; border-collapse: collapse; width: 80%; margin-left: 10%; margin-right: 10%; background-color:#FFF;})
		head_html << %(	.sample-head-table th, td {padding: 8px; text-align: left; border-bottom: 2px solid #103d5d;})
		head_html << %(	.sample-head-table tr:hover {background-color:#a4d0f0;})
		head_html << %(	.sample-head-table td:first-child {font-weight: bold;})
		head_html << %(	.sample-head-table-title {padding: 8px; border-collapse: collapse; width: 80%; margin-left: 10%; margin-right: 10%;font-weight: bold; font-size: large; text-decoration: underline; text-align: center;})		
        head_html << %(	h1,h2,h3,h4 {text-align:center;})
        head_html << %(	h1 {background-color:#103d5d; color: #fff;})
        head_html << %(	h3,h4 {color: #103d5d;})        
        head_html << %(	h2 {background-color:#3f9cde; color: #fff;})
        head_html << %(	h3 {background-color:#82bfea;})
        head_html << %(	h4 {background-color:#b5d9f3;})
        head_html << %(	p {text-align:justify; padding:8px;})
        head_html << %( body {color:#071c2b})
        head_html << %(	.flex-row {display:flex; align-items:center; justify-content:center;})
        head_html << %(	.flex-column-50 {flex: 50%; align-items:center; justify-content:center;})
        head_html << %(	.flex-column-80 {flex: 80%; align-items:center; justify-content:center;})        
        head_html << %(	.flex-canvas-50 {display:flex; flex: 50%; align-items:center; justify-content:center;})
        head_html << %(	.flex-canvas-80 {display:flex; flex: 80%; align-items:center; justify-content:center;})
		head_html << %(</style>)
        head_html << %(	<h1>SeqTrimBB preprocessing report</h1>)
        head_html << %(	<p style="text-align:center;"> This report collect all the relevant information generated on SeqTrimBB execution. <br> <b> Please, wait the report's loading to finish </b> </p>)
        add_to_template(head_html)
	end

	def add_to_template(str)
	  #if str is an array, join it in a string	
		if str.is_a?(Array)
        	str = str.join("\n")
		end
	  #add str to template	
		@@template << str

		if str.chars.last(2) != "\n"
			@@template << "\n"
	    end
	end

	# def prepare_json(json)
	# 	json.each do |key,value|
	# 		if value.is_a?(Hash)
	# 			@@container[key] = value.to_a
	# 		else
	# 			@@container[key] = value
	# 		end
	# 	end
	# end

	def get_output(output_folder)	
		return File.join(output_folder,"report.html")
	end

end