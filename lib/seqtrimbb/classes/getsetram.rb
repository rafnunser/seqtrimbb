class GetSetRAM

  attr_reader :value

#Gets free ram
  def initialize
#Sys call (free -g) and output split
    raw_output=%x(free -g)   
    lines = raw_output.split("\n")
#Find in header free memory index
    index_freemem = lines[0].split(" ").find_index("free")
#Find and calculate free memory
    free_ram = lines[1].split(":").last.split(" ")[index_freemem]
    calc_ram = (free_ram.to_i * 0.85 - 0.5).round

    if calc_ram.to_i >= 4
      @value = [calc_ram,'g'].join("")
    else
      @value = '4g'
    end
  end
end