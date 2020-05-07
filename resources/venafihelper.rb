resource_name :venafihelper

property :tpp_url, String, name_property: true
property :tpp_password, String
property :tpp_username, String
property :policyname, String
property :commonname, String
property :location, String
property :devicename, String

require 'json'
require 'net/http'
require 'uri'
require 'openssl'
require 'base64'
require 'socket'
require 'date'
require 'fileutils'


action :run do
  require 'vcert'
  TPP_URL = "#{new_resource.tpp_url}"
  TPP_SDK_URL = "#{TPP_URL}/vedsdk/"
  TPP_USERNAME = "#{new_resource.tpp_username}"
  TPP_PASSWORD = "#{new_resource.tpp_password}"
  CERTIFICATE_ZONE = "#{new_resource.policyname}"
  COMMON_NAME = "#{new_resource.commonname}"
  DEVICE_NAME = "#{new_resource.devicename}"

  CERT_FILE="#{COMMON_NAME}.cert"
  KEY_FILE="#{COMMON_NAME}.key"
  CHAIN_FILE="#{COMMON_NAME}.chain"

  PATH = "#{new_resource.location}"
  CERT_PATH="#{PATH}/#{CERT_FILE}"
  KEY_PATH="#{PATH}/#{KEY_FILE}"
  CHAIN_PATH="#{PATH}/#{CHAIN_FILE}"
  CERT_ID="\\VED\\Policy\\#{CERTIFICATE_ZONE}\\#{COMMON_NAME}"

  TOKEN_HEADER_NAME = "x-venafi-api-key"
  URL_AUTHORIZE = "/authorize/"
  URL_CONFIG_CREATE = "/config/create"
  URL_CERT_ASSOCIATE = "/certificates/associate"
  URL_CERTIFICATE_SEARCH = "/certificates/"

  @conn = Vcert::Connection.new url: TPP_URL, user: TPP_USERNAME, password: TPP_PASSWORD
  @zone_config = @conn.zone_configuration(CERTIFICATE_ZONE)

  # apikey = authorize['APIKey']
  # puts "API-key #{apikey}"
  if !(::File.exists?("#{CERT_PATH}"))
    requestAndRetrieve
    # sleep(60)
    # apikey = authorize['APIKey']
    # puts "API-key #{apikey}"
    # retrievecert(apikey)
    # apikey = authorize['APIKey']
    deviceCreation
  end

  checkExpiry
end


action_class do
  
  def authorize
    uri = URI.parse(TPP_SDK_URL)
    request = Net::HTTP.new(uri.host, uri.port)
    request.use_ssl = true
    url = uri.path + URL_AUTHORIZE
    data = {:Username => TPP_USERNAME, :Password => TPP_PASSWORD}
    encoded_data = JSON.generate(data)
    response = request.post(url, encoded_data, {"Content-Type" => "application/json"})
    data = JSON.parse(response.body)
    token = data['APIKey']
    valid_until = DateTime.strptime(data['ValidUntil'].gsub(/\D/, ''), '%Q')
    @token = token, valid_until
  end

  def post(url, data)
    if @token == nil || @token[1] < DateTime.now
      authorize()
    end
    uri = URI.parse(TPP_SDK_URL)
    request = Net::HTTP.new(uri.host, uri.port)
    request.use_ssl = true
    url = uri.path + url
    encoded_data = JSON.generate(data)
    response = request.post(url, encoded_data, {TOKEN_HEADER_NAME => @token[0], "Content-Type" => "application/json"})
    data = JSON.parse(response.body)
    return response.code.to_i, data
  end

  def get(url)
    if @token == nil || @token[1] < DateTime.now
      authorize()
    end
    uri = URI.parse(TPP_SDK_URL)
    request = Net::HTTP.new(uri.host, uri.port)
    request.use_ssl = true
    url = uri.path + url
    response = request.get(url, {TOKEN_HEADER_NAME => @token[0]})
    data = JSON.parse(response.body)
    return response.code.to_i, data
  end

  def requestAndRetrieve
    
    request = Vcert::Request.new common_name: COMMON_NAME

    request.update_from_zone_config(@zone_config)

    certificate = @conn.request_and_retrieve(request, CERTIFICATE_ZONE, timeout: 600)

    puts "Private Key is:\n#{request.private_key}"
    puts "Certificate is:\n#{certificate.cert}"
    puts "Chain is:\n#{certificate.chain.join("")}"

    ::FileUtils.mkpath "#{PATH}"
    
    ::File.open("#{CERT_PATH}", "w+") {|f| f.write("#{certificate.cert}") }
    ::File.open("#{KEY_PATH}", "w+") {|f| f.write("#{request.private_key}") }
    ::File.open("#{CHAIN_PATH}", "w+") {|f| f.write("#{certificate.chain.join("")}") }
  end

  def deviceCreation
    ip = Socket.ip_address_list.detect{|intf| intf.ipv4_private?}
    deviceDN = "\\VED\\Policy\\Devices and Applications\\External\\#{DEVICE_NAME}"
    applicationDN = "#{deviceDN}\\#{COMMON_NAME}-#{ip.ip_address}/#{Socket.gethostname}"

    deviceCreationData = {:ObjectDN => deviceDN, :Class => "Device", :NameAttributeList =>[{:Name => "Description", :Value => "Value"}]}
    applicationCreationData = {:ObjectDN => applicationDN, :Class => "Basic", :NameAttributeList =>[{:Name => "Description", :Value => "Basic Application for certificate #{COMMON_NAME}"},{:Name => "Disabled", :Value => "0"}]}
    associateData = {:ApplicationDN => applicationDN, :CertificateDN => CERT_ID}
    
    deviceCode, deviceResponse = post URL_CONFIG_CREATE, deviceCreationData
    if deviceCode != 200
      return nil
    end
    puts deviceResponse

    applicationCode, applicationResponse = post URL_CONFIG_CREATE, applicationCreationData
    if applicationCode != 200
      return nil
    end
    puts applicationResponse

    associateCode, associateResponse = post URL_CERT_ASSOCIATE, associateData
    if associateCode != 200
      return nil
    end
    puts associateResponse    
  end

  def checkExpiry
    oldCert = ::File.read CERT_PATH
    certificateObject = OpenSSL::X509::Certificate.new(oldCert)
    thumbprint = OpenSSL::Digest::SHA1.new(certificateObject.to_der).to_s
    thumbprint = thumbprint.upcase
    status, data = get(URL_CERTIFICATE_SEARCH+"?Thumbprint=#{thumbprint}")
    certInfo = data['Certificates'].first
    
    validTo = certInfo['X509']['ValidTo']
    puts validTo
    validTo = DateTime.parse("#{validTo}").to_datetime
    puts validTo
    validTo = validTo - 10
    puts validTo
    currentDate = DateTime.now
    puts currentDate

    if currentDate > validTo
      puts "test"
      renew_request = Vcert::Request.new
      renew_request.thumbprint = thumbprint
      renew_cert_id, renew_private_key = @conn.renew(renew_request)
      renew_request.id=renew_cert_id
      renew_cert = @conn.retrieve_loop(renew_request)
      puts "New private key is:\n" + thumbprint_renew_private_key
      puts "Renewed certificate is:\n" + thumbprint_renew_cert.cert
      puts "test"
    else                 
      puts "test2"
    end
  end
end