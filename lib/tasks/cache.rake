namespace :cache do
  desc "Clear Rails cache"
  task :clear => [ :environment ] do
    Rails.cache.clear
  end

  desc "Remove minified js and css files"
  task :clear_minified do 
    %w{javascripts/jquery_all.js javascripts/all.js stylesheets/all.css stylesheets/new_all.css}.each do |file|
      sh("rm -rf #{RAILS_ROOT}/public/#{file}")
    end
  end
end
