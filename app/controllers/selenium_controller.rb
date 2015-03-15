class SeleniumController < ApplicationController
  # Reset current session, to be used during Selenium testing only!
  def reset
    raise "Available only in test environment" unless RAILS_ENV == "test"
    reset_session
    reset_cookies
    Rails.cache.clear
    render :nothing => :true
  end
  
  protected
  def reset_cookies
    cookies.each do |key, value|
      cookies.delete key
    end
  end
end
