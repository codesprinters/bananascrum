class JuggernautMessage
  attr_accessor :body, :channels
  def initialize(body, channels)
    self.body = body
    self.channels = channels
  end
end