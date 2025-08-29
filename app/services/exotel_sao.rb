require 'net/http'
require 'uri'

class ExotelSao

  class << self

    def secure_post url, request_body
      response = RestClient.post(url, request_body)
      response = JSON.parse(response)
    end

  end

end