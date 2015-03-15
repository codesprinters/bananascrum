namespace :doc do
  desc "Builds documentation in all possible formats from RST"
  task :sphinx => ['doc:sphinx:clean', 'doc:sphinx:html', 'doc:sphinx:txt']
  namespace :sphinx do
    desc "Clears all documentation generated from sphinx"
    task :clean do
      system "cd #{RAILS_ROOT}/doc && make clean"
    end
    desc "Compiles rst docs into html"
    task :html do
      system "cd #{RAILS_ROOT}/doc && mkdir -p _build/html && make html"
    end
    desc "Compiles rst docs into plain text"
    task :txt do
      system "cd #{RAILS_ROOT}/doc && mkdir -p _build/txt && make txt"
    end
    desc "Creates deployment.pdf file from deployment.rst"
    task :deployment_pdf do
      system "cd #{RAILS_ROOT}/doc && rst2pdf deployment.rst -o deployment.pdf"
    end
  end
end
