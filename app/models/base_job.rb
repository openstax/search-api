class BaseJob
  attr_reader :type

  def initialize
    @type = self.class.to_s
  end
end
