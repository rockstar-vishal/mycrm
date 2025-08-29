class ExternalService

  def initialize(company, params={})
    @company = company
    @params = params
  end

  def create_client
    url = @company.postsale_url
    if url.present?
      begin
        RestClient.post(url+"/internal/clients.json", @params, {content_type: "application/json", accept: 'application/json'})
      rescue => e
        []
      end
    end
  end

  def create_broker
    url = @company.postsale_url
    if url.present?
      begin
        RestClient.post(url+"/internal/brokers.json", @params, {content_type: "application/json", accept: 'application/json'})
      rescue => e
        []
      end
    end
  end

  def fetch_flats
    url = @company.postsale_url
    if url.present?
      begin
        RestClient.get(url+"/internal/flats", {params: {building_id: @params["building_id"]}})
      rescue => e
        []
      end
    end
  end

  def fetch_projects
    url = @company.postsale_url
    if url.present?
      begin
        return RestClient.get(url+"/internal/flats/get_projects", {content_type: "application/json", accept: "application/json"})
      rescue => e
        []
      end
    end
  end

  def fetch_buildings
    url = @company.postsale_url
    if url.present?
      begin
        return RestClient.get(url+"/internal/flats/get_buildings", {params: {id: @params["project_id"]}})
      rescue => e
        []
      end
    end
  end

  def block_flat
    url = @company.postsale_url
    if url.present?
      begin
        RestClient.post(url+"/internal/flats/#{@params[:id]}/block", @params, {content_type: "application/json", accept: 'application/json'})
      rescue => e
        return []
      end
    end
  end

end