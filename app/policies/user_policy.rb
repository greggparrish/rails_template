class UserPolicy < ApplicationPolicy
  attr_reader :current_user, :user
  def initialize(current_user, model)
    @current_user = current_user
    @user = model
  end 

  class Scope < Scope
    def resolve
      scope.all
    end 
  end 

  def index?
    @current_user.admin?
  end

  def show?
    @current_user.admin? or @@current_user = @user 
  end

  def create?
    @current_user.admin?
  end

  def update?
    @current_user.admin?
  end
 
  def destroy?
    return false if @current_user == @user
    @current_user.admin?
  end
 
end


