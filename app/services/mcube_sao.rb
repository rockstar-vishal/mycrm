require 'net/http'
require 'uri'

class McubeSao

  class << self

    def secure_get url
      response = RestClient.get(url)
      response = JSON.parse(response)
    end

  end

end