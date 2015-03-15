module FindActivation

  protected

  def find_activation
    @activation = UserActivation.find_by_key(params[:key])
    unless @activation
      @activation = UserActivation.new(:key => params[:key])
      @activation.errors.add(:key, 'is invalid') if params[:key]
    end
  end
  
end