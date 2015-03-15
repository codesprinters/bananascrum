require 'java'
require 'base64.jar'
include_class("Base64") {
  |package,name| "J#{name}"
}

class LicenseKey::Validator < LicenseKey
  DATA_PARTS_SIZE = 2

  attr_reader :signature, :company, :entity_name, :valid_to

  def initialize(license_key, major_version = nil)
    super(major_version)
    parse_license(license_key)
  end

  def valid?
    public_key = OpenSSL::PKey::RSA.new(File.read(File.join(rsa_path, 'id_rsa.pub')))
    return !@signature.blank? && public_key.verify(OpenSSL::Digest::SHA1.new, @signature, @message)
  end

  protected

  def parse_license(license_key)
    return if license_key.nil? || license_key.empty?

    parts = license_key.split("\n")
    # remove redundant whitespaces
    parts = parts.map(&:strip)
    # remove begin/end markers and empty lines
    parts = parts.delete_if { |f| f.match('^=====') || f.empty? }
    return if parts.empty?

    # extract data stored in license key
    data = parts.shift
    begin
      data_parts = data.split(':', DATA_PARTS_SIZE).map { |f| String.from_java_bytes(JBase64.decode(f)) }
      # extract license key signature
      signature = String.from_java_bytes JBase64.decode(parts.map(&:chomp).join("\n"))
    rescue java.io.IOException
      # no reason to continue
      return false
    rescue java.lang.IllegalArgumentException
      return false
    rescue java.lang.NullPointerException
      return false
    end
    
    if data_parts.try(:size) == DATA_PARTS_SIZE
      entity_name, valid_to = *data_parts

      begin
        @valid_to = Date.parse(valid_to) unless valid_to.empty?

        @signature = signature
        @message = data
        @entity_name = entity_name
      rescue ArgumentError 
        # rescue parsing date error
      rescue java.lang.ArrayIndexOutOfBoundsException
      end
    end
  end

end
