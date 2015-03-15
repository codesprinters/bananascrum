namespace :java do
  desc "Build native-java extensions"
  task :build do
    sh "cd #{RAILS_ROOT}/vendor/gems/eventmachine* && rake java:build"
  end
end
