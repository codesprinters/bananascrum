require File.dirname(__FILE__) + '/../../test_helper'
require 'license_key/validator'

class LicenseKey::ValidatorTest < ActiveSupport::TestCase

  def self.test_valid_license(context_name, license)
    context context_name do
      setup { @license_key = LicenseKey::Validator.new(license) }
      should('be valid') { assert @license_key.valid? }
    end
  end

  def self.test_invalid_license(context_name, license)
    context context_name do
      setup { @license_key = LicenseKey::Validator.new(license) }
      should('be invalid') { assert !@license_key.valid? }
    end
  end

  test_valid_license('company license', Factory.build(:company_license).key)
  test_valid_license('personal license', Factory.build(:personal_license).key)

  license = "
     ===== LICENSE BEGIN =====\n
          Q29kZSBTcHJpbnRlcnM=:\n\r
\r\raU+O4jSqR3xTdrXJDOyJEcKweTdwdXmfzDeymv4R0JbyO4hoSM35Cg/7FUyF\n
\t\tyo1/B3XCEm0mdRkRcmc2ZSpaBt5UWDHAjrZU/U7g1AMV1ijC1PwvrSsUIxn5\r\n
          cmP2HugL8p+uSciuNDZVP2Mm0Jnk3GNjzMMi5LO/9Ux0em/9N34=\n
===== LICENSE END =======
"
  test_valid_license('license with extra whitespaces', license)

  license = <<LICENSE
  ===== LICENSE BEGIN =====
Q29kZSBTcHJpbnRlcnM=:
here is an
invalid
rsa signature
===== LICENSE END =======
LICENSE
  test_invalid_license('license with invalid signature', license)

  license = <<LICENSE
===== LICENSE BEGIN =====
Sm9obiBEb2U=:invalid_date_string
J9+ThrECb7dgt6h+0tG3+0Enf8koA4kQDf9IjkqGO0s09/HrlZMaNZFmgaqK
GP2dlt0cB63sZdWn3H/9fYX1LGn0GfK/faXMKPv2Ogyo7iCHo5d8r1PKKZeO
89X45CTDjHcn5fsRwtbDJqyj/eyVCRi03DpMqdhdKH8oNG48opQ=
===== LICENSE END =======
LICENSE
  test_invalid_license('license with invalid valid_to date', license)

  license = '===== LICENSE BEGIN =====\nQ29kZSBTcHJpbnRlcnM=:\naU+O4jSqR3xTdrXJDOyJEcKweTdwdXmfzDeymv4R0JbyO4hoSM35Cg/7FUyF\nyo1/B3XCEm0mdRkRcmc2ZSpaBt5UWDHAjrZU/U7g1AMV1ijC1PwvrSsUIxn5\ncmP2HugL8p+uSciuNDZVP2Mm0Jnk3GNjzMMi5LO/9Ux0em/9N34=\n===== LICENSE END ======='
  test_invalid_license('license with invalid format', license)

  test_invalid_license('empty license key', nil)

end
