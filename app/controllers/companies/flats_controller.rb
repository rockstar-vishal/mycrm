class Companies::FlatsController < ApplicationController

  def fetch_biz_flats
  end

  def fetch_projects
    es = ExternalService.new(current_user.company)
    projects = es.fetch_projects
    if projects.present?
      @projects = JSON.parse(projects)
    end
    render json: @projects, status: 200 and return
  end

  def fetch_buildings
    project_id = params[:id]
    request = {"project_id" => project_id}
    es = ExternalService.new(current_user.company, request)
    buildings = es.fetch_buildings
    @buildings = JSON.parse(buildings)
    render json: @buildings, status: 200 and return
  end

  def fetch_building_flats
    building_id = params[:id]
    request = {"building_id" => building_id}
    es = ExternalService.new(current_user.company, request)
    flat_details = es.fetch_flats
    if flat_details.present?
      flat_details = JSON.parse(flat_details)
      @flats = flat_details["flats"]
      @floors=flat_details["floors"]
    end
    respond_to do |format|
      format.js do
        @flat_details = flat_details
      end
    end
  end

  def flat_block_modal
    @flat_id = params["id"]
    @flat_name = params["name"]
    @building_id = params["building_id"]
    render_modal('flat_block_modal')
  end

  def block_flat
    flat_id=params[:flat_id]
    flat_name=params[:flat_name]
    user_ids = params[:user_ids]
    date = params[:date]
    comment = params[:comment] rescue ''
    request = {id: flat_id, :user_ids => user_ids, date: date, comment: comment}
    es = ExternalService.new(current_user.company, request)
    flat_block = es.block_flat
    flat_block = JSON.parse(flat_block)
    render json: flat_block, status: 200 and return
  end

end