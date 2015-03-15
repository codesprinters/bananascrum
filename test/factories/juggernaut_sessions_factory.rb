Factory.define :juggernaut_session do |js|
  js.project { DomainChecks.disable{ Project.find_by_name('bananorama') } }
  js.domain { DomainChecks.disable{ Domain.find_by_name('cs') } }
  js.user { DomainChecks.disable{ User.find_by_login('aczajka') } }
end