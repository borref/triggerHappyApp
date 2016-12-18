require 'net/http'

module RESTClient

  @@CLIENT_ID = '4e6d252e6763abb3f78d'
  @@CLIENT_SECRET = 'e0c6b9263d2439728439ce56e68d7483e3050158'

  class Response

    attr_accessor :status_code, :body, :next_page_url

    # Builder
    def initialize(status_code, response_body, next_page_url = nil)
      @status_code = status_code
      @body = response_body
      @next_page_url = next_page_url
    end  
  end

  def set_base_url(url)
    @@base_url = url    
  end

  # Parse the Link header from the API request into a hash
  def parse_link_header(header)
    links = {}

    parts = header.split(',').each do |part|
      page = part.split(';')
      relative_url = page[0][/<https:\/\/api.github.com(.*)>/, 1]
      name = page[1][/rel="(.*)"/, 1].to_sym
      links[name] = relative_url
    end

    links
  end

  def make_request(method, request_url, params = {})
    uri = URI(@@base_url + request_url)
    response, next_page = nil

    case method
    when 'GET'
      unless request_url.include? 'client_id'
        params.merge!({ "client_id" => @@CLIENT_ID, "client_secret" => @@CLIENT_SECRET })
        uri.query = URI.encode_www_form(params)
      end

      req = Net::HTTP::Get.new(uri)
    when 'POST'
      req = Net::HTTP::Post.new(uri)
      req.set_form_data(params)
    else
      return nil
    end
    
    res = Net::HTTP.start(uri.host, uri.port, :use_ssl => uri.scheme == 'https') { |http|
      http.request(req)
    }

    # Check if there are more pages by looking up the link header
    link_header = res['link']
    if link_header
      parsed_link_header = parse_link_header(link_header)
      next_page = parsed_link_header[:next]
    end

    response = Response.new(res.code, res.body, next_page) if res.is_a?(Net::HTTPSuccess)
  end

  module_function :set_base_url, :make_request, :parse_link_header
end