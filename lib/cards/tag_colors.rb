class TagColors
  attr_reader :map, :white

  def self.getForeground(id)
    self.build_map if @map.nil?
    color = @map[id]['foreground']
    return color[0],color[1],color[2]
  end

  def self.getBackground(id)
    self.build_map if @map.nil?
    color = @map[id]['background']
    return color[0],color[1],color[2]
  end

  protected
  def self.build_map
    @white = [255,255,255]
    @map = {
      1 => {'foreground' => @white, 'background' => [180,52,35]},
      2 => {'foreground' => [180,52,35], 'background' => @white},
      3 => {'foreground' => @white, 'background' => [252,116,4]},
      4 => {'foreground' => [252,116,4], 'background' => @white},
      5 => {'foreground' => @white, 'background' => [243,197,38]},
      6 => {'foreground' => [243,197,38], 'background' => @white},
      7 => {'foreground' => @white, 'background' => [244,201,140]},
      8 => {'foreground' => [244,201,140], 'background' => @white},
      9 => {'foreground' => @white, 'background' => [44,28,3]},
      10 => {'foreground' => [44,28,3], 'background' => @white},
      11 => {'foreground' => @white, 'background' => [89,62,18]},
      12 => {'foreground' => [89,62,18], 'background' => @white},
      13 => {'foreground' => @white, 'background' => [148,133,4]},
      14 => {'foreground' => [148,133,4], 'background' => @white},
      15 => {'foreground' => @white, 'background' => [140,188,24]},
      16 => {'foreground' => [140,188,24], 'background' => @white},
      17 => {'foreground' => @white, 'background' => [6,53,199]},
      18 => {'foreground' => [6,53,199], 'background' => @white},
      19 => {'foreground' => @white, 'background' => [146,84,168]},
      20 => {'foreground' => [146,84,168], 'background' => @white},
      21 => {'foreground' => @white, 'background' => [91,108,138]},
      22 => {'foreground' => [91,108,138], 'background' => @white},
      23 => {'foreground' => @white, 'background' => [155,165,232]},
      24 => {'foreground' => [155,165,232], 'background' => @white},
    }
    return @map
  end
end
