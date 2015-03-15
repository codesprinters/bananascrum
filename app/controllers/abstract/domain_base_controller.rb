# Just a wrapper around DomainAndAuthorization mixin.
# It just imports that module and should not do anything more
# the module must be fully usable outside this inheritance hierarchy
class DomainBaseController < ApplicationController
  protected
  include DomainAndAuthorization
end
