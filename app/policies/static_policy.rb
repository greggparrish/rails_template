class StaticPolicy < Struct.new(:user, :static)

  def index?
    true
  end

  def home?
    true
  end

end


