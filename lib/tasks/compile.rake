namespace :war do
  desc "Create compiled war"
  task "compile" =>  ["cache:clear_minified", "war:app", "war:public", "war:webxml"] do
    FileUtils.cd("#{RAILS_ROOT}/tmp/war/WEB-INF") do
      # compile rb files
      sh "jrubyc -p '' app lib"
      # remove rb file
      sh "find app lib -name '*.rb' | xargs rm"
      # remove doc directory
      sh "rm -rf doc"
    end

    Rake::Task["war:jar"].invoke
  end

  desc "Create documentation for compiled distribution"
  task "doc" => ['doc:sphinx:txt', 'doc:sphinx:deployment_pdf'] do
    sh "cd #{RAILS_ROOT} && cp doc/_build/txt/deployment.txt build/README"
    sh "cd #{RAILS_ROOT} && cp doc/deployment.pdf build/README.pdf"
  end
  desc "Create bananascrum dist package"
  task "package" => ['war:compile', 'war:doc']
end
