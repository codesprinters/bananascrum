require File.dirname(__FILE__) + '/../../test_helper'
require 'base64'

class LicenseKey::GeneratorTest < ActiveSupport::TestCase

  context 'public and private keypair generation' do
    setup do
      # create tmp dir for keypair
      @tmpdir = "/#{Dir.tmpdir}/bs-licenses-#{rand(0x100000000).to_s(36)}"
      Dir.mkdir(@tmpdir, 0700)
      
      @generator = LicenseKey::Generator.new(BananaScrum::Version::MAJOR)
      @generator.expects(:rsa_path).at_least_once.returns(@tmpdir)
    end

    teardown do
      FileUtils.rm_rf(@tmpdir)
    end

    should 'generate keypair' do
      assert_nothing_raised do
        keypair = @generator.generate_keypair
        assert keypair
      end
    end

    should 'not generate keypair twice' do
      @generator.generate_keypair
      assert_raise Exception do
        @generator.generate_keypair
      end
    end
  end

  context 'license generation' do
    setup { @generator = LicenseKey::Generator.new(BananaScrum::Version::MAJOR) }

    should 'generate license' do
      test_for = lambda do |license|
        license = Factory.build(license)
        license_key = @generator.generate_license(license.entity_name, license.valid_to)
        assert_equal license.key.chomp, license_key, "Invalid key for #{license}"
      end

      test_for.call(:company_license)
      test_for.call(:personal_license)
    end
  end

end
