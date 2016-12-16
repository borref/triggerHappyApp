require 'net/http'

module RESTClient

  @@CLIENT_ID = '4e6d252e6763abb3f78d'
  @@CLIENT_SECRET = 'e0c6b9263d2439728439ce56e68d7483e3050158'

  class Response

    attr_accessor :status_code, :response_body, :next_page_url

    # Builder
    def initialize(status_code, response_body, next_page_url = nil)
      @status_code = status_code
      @response_body = response_body
      @next_page_url = next_page_url
    end  
  end

  def set_base_url(url)
    @@base_url = url    
  end

  def make_request(method, request_url, params = {})
    uri = URI(@@base_url + request_url)

    puts "\n\nURL\n\n"
    p uri
    puts "\n"

    case method
    when 'GET'
      params.merge!({ "client_id" => @@CLIENT_ID, 
                      "client_secret" => @@CLIENT_SECRET })
      uri.query = URI.encode_www_form(params)
      req = Net::HTTP::Get.new(uri)
    when 'POST'
      req = Net::HTTP::Post.new(uri)
      req.set_form_data(params)
    else
      res = nil
    end
    
    res = Net::HTTP.start(uri.host, uri.port, :use_ssl => uri.scheme == 'https') { |http|
      http.request(req)
    }

    puts "\n\nURL\n\n"
    p res.to_hash['link']
    puts "\n"

    response = res.is_a?(Net::HTTPSuccess) ? Response.new(res.code, res.body) : nil
  end

  module_function :set_base_url, :make_request
end