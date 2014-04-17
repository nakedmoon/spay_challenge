class CustomResponseError < StandardError
  attr_accessor :error_array

  def initialize(error_array = [], message = nil)
    super(message)
    self.error_array = error_array
  end

end

class ApiResponse

  attr_reader :offers, :error, :code, :message, :http_code, :pages, :count
  attr_accessor

  HEADER_SIGNATURE_KEY = 'X-Sponsorpay-Response-Signature'

  def initialize(response, request_key)
    begin
      @offers = []
      @error = false
      @pages = 0
      Rails.logger.debug "Getting response: #{response.body}"
      @http_code = response.code
      response_body = response.body
      @header_signature = response.header[HEADER_SIGNATURE_KEY]
      @request_signature = Digest::SHA1.hexdigest(response_body + request_key)
      response_hash = JSON.parse(response_body)
      @code, @message = [response_hash['code'], response_hash['message']]
      unless invalid_http_code? # If invalid_http_code SponsorPay not send signature header
        raise CustomResponseError(['UNTRUSTED_RESPONSE', 'Untrusted response!']) if untrusted?
        @pages = response_hash['pages']
        @count = response_hash['count']
        @offers = response_hash['offers'].map{|offer| {title: offer['title'],
                                              payout: offer['payout'],
                                              thumbnail: offer['thumbnail']['lowres']}
        }
      else
        @error = true
      end
    rescue CustomResponseError => e
      @error = true
      @code, @message = e.error_array
    rescue StandardError => e
      @error = true
      @code, @message = ["#{e.class.to_s.underscore.upcase}", ActionController::Base.helpers.truncate(e.message, :length => 30)]
    end
  end

  def missing_header_signature?
    !@header_signature.present?
  end

  def invalid_http_code?
    @http_code.to_i!=200
  end

  def error?
    @error == true
  end

  def untrusted?
    @header_signature != @request_signature
  end

  def no_offers?
    @offers.empty?
  end

end

class ApiClient
  include ActiveModel::Model # Using active model for basic validations and form helper


  OFFER_TYPES = {100 => {name: "Mobile", description: "Mobile subscription offers"},
                 101 => {name: "Download", description: "Download offers"},
                 102 => {name: "Trial", description: "Trial offers"},
                 103 => {name: "Sale", description: "Shopping offers"},
                 104 => {name: "Registration", description: "Information request offers"},
                 105 => {name: "Registration", description: "Registration offers"},
                 106 => {name: "Games", description: "Gaming offers"},
                 107 => {name: "Games", description: "Gambling offers"},
                 108 => {name: "Registration", description: "Data generation offers"},
                 109 => {name: "Games", description: "Games offers"},
                 110 => {name: "Surveys", description: "Survey offers"},
                 111 => {name: "Registration", description: "Dating offers"},
                 112 => {name: "Free", description: "Free offers"},
                 113 => {name: "Video", description: "Video offers"}

  }

  # Validation based on documentation found at http://developer.sponsorpay.com/content/ios/offer-wall/offer-api/
  validates :url, :key, :appid, :device_id, :offer_descriptions_locale, :uid, presence: true
  validates :response_page, numericality: true, presence: false, allow_blank: true
  validates :offer_types_filter, presence: false, inclusion: { in: OFFER_TYPES.keys}
  validates :response_format, inclusion: { in: [:json, :xml]}, presence: true


  attr_accessor :url,
                :key,
                :uid,
                :pub0,
                :appid,
                :ip,
                :response_page,
                :response_format,
                :device_id,
                :offer_descriptions_locale,
                :offer_types_filter

  # Protected parameters
  attr_reader :hashkey
  attr_reader :response
  attr_reader :timestamp

  DEFAULT_PARAMETERS = {
      url: 'http://api.sponsorpay.com/feed/v1/offers.json',
      key: 'b07a12df7d52e6c118e5d47d3f9e60135b109a1f',
      appid: 157,
      response_format: :json,
      device_id: 'my_device',
      offer_descriptions_locale: :de,
      ip: '109.235.143.113',
      offer_types_filter: 112
  }

  def initialize(params={})
    @response = nil
    @hashkey = nil
    super(DEFAULT_PARAMETERS.merge(params)) # Using default params when not passed to constructor
  end

  def save
    return false if invalid?
    send_request and return true
  end


  private

    def send_request
      uri = URI.parse(@url)
      @timestamp = Time.now.to_i
      # initialize uri params hash
      uri_params_hash = ({
          appid: @appid,
          format: @response_format,
          device_id: @device_id,
          locale: @offer_descriptions_locale,
          ip: @ip,
          offer_types: @offer_types_filter,
          uid: @uid,
          pub0: @pub0,
          page: @response_page,
          timestamp: @timestamp
      })
      # Get hashkey from uri params hash
      @hashkey = get_hashkey(uri_params_hash)
      # Add hashkey to uri params hash and encode the uri params hash
      uri.query = URI.encode_www_form(uri_params_hash.merge(hashkey: @hashkey))
      # Populate response with ApiResponse object instance and passing it key for signature verification
      Rails.logger.debug "Sending request: #{uri}"
      @response = ApiResponse.new(Net::HTTP.get_response(uri), key)
    end

    def get_hashkey(api_params)
      hash_pairs = api_params.to_param # Transfor hash to url paramaters: key=value pairs separated by &
      calculation_string = [hash_pairs, @key].join('&') # Concatenate the resulting string with & and the API Key
      Digest::SHA1.hexdigest(calculation_string)
    end





end