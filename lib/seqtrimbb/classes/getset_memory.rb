# Returns 85% of the avalaible RAM in the system

def getset_memory
     
     available_ram=[]
     raw_output=%x(free -g)
     splitted_output=raw_output.split(" ")
     free_ram = (splitted_output[12].to_i * 0.85 - 0.5).round
     available_ram.push(free_ram.to_s)
     available_ram.push("G")

     max_ram = available_ram.join("")

end



    
