require 'java'
require 'base64.jar'
include_class "Base64"

class LicenseKey::Generator < LicenseKey

  def generate_keypair
    private_key = File.join(rsa_path, 'id_rsa')
    public_key = File.join(rsa_path, 'id_rsa.pub')

    unless File.exists?(private_key) || File.exists?(public_key)
      Dir.mkdir(rsa_path) unless File.exist?(rsa_path)

      key_pair = OpenSSL::PKey::RSA.generate(1024)
      File.open(private_key, 'w') { |f| f.write(key_pair.to_pem) }
      File.open(public_key, 'w') { |f| f.write(key_pair.public_key.to_pem) }

      return key_pair
    else
      raise Exception, "Keys for major version #{@major_version} already exist!"
    end
  end

  def generate_license(entity_name, valid_to = nil)
    private_key = OpenSSL::PKey::RSA.new(File.read(File.join(rsa_path, 'id_rsa')))

    data = [entity_name, valid_to.to_s].map { |f| Base64.encodeBytes(f.to_java_bytes).chomp }.join(':')
    signature = private_key.sign(OpenSSL::Digest::SHA1.new, data)

    license_key =  "===== LICENSE BEGIN =====\n"
    license_key << data + "\n"
    license_key << Base64.encodeBytes(signature.to_java_bytes).chomp + "\n"
    license_key << "===== LICENSE END ======="
    
    return license_key
  end
    
end
