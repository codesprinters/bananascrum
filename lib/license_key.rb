require 'openssl'
require 'base64'

class LicenseKey
  def initialize(major_version = nil)
    @major_version = (major_version || BananaScrum::Version::MAJOR).to_s
  end

  def rsa_path
    return File.join(RAILS_ROOT, 'licenses', @major_version)
  end
end
