module HTTPSao
  class << self

    def secure_get url, params={}
      begin
        url = URI url
        url.query = URI.encode_www_form(params) if params.present?
        http = Net::HTTP.new(url.host, url.port)
        request = Net::HTTP::Get.new(url)
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE
        response = http.request(request)
        response_body = JSON.parse response.body
        return true, response.code, response_body
      rescue Exception => e
        return false, 0, e
      end
    end

    def secure_post url, request_body
      uri = URI.parse url
      req = Net::HTTP::Post.new(uri.path, initheader = {'Content-Type' =>'application/json'})
      http = Net::HTTP.new(uri.host,uri.port)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      req.body = request_body
      response = http.request(req)
      response_data = JSON.parse response.body
      if response.kind_of?(Net::HTTPSuccess)
        response_object = response_data["data"]
        success = response_object["success"] rescue "-"
        failures = response_object["errors"] rescue "-"
        return true, {:success=>success, :failures=>failures}
      else
        return false, {:success=>nil, :failures=>response_data["message"]}
      end
    end
  end
end