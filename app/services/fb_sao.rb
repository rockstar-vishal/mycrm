require 'net/http'
require 'uri'

class FbSao

  class << self

    def extend_token token
      url = "https://graph.facebook.com/v10.0/oauth/access_token?"
      to_send_data = {grant_type: 'fb_exchange_token', client_id: CRMConfig.fb_app_id, client_secret: CRMConfig.fb_app_secret, fb_exchange_token: token}
      final_url = "#{url}#{to_send_data.to_query}"
      status, code, body = HTTPSao.secure_get final_url
      return status, body
    end

  end

end