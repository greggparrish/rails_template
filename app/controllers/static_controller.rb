class StaticController < ApplicationController
  def home
    authorize :static, :home?
  end

  def about
    authorize :static, :about?
  end

end

