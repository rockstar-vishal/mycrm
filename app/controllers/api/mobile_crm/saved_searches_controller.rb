module Api
  module MobileCrm
    class SavedSearchesController < ::Api::MobileCrmController
      before_action :find_search, only: [:destroy]
      def index
        searches = @current_app_user.search_histories.select("id, name").as_json
        render json: {searches: searches}, status: 200 and return
      end

      def create
        history = @current_app_user.search_histories.build(save_search_params)
        if history.save
          render json: {message: "Success"}, status: 200 and return
        else
          render json: {message: history.errors.full_messages.join(', ')}, status: 400 and return
        end
      end

      def destroy
        if @search.destroy
          render json: {message: "Success"}, status: 200 and return
        else
          render json: {message: @search.errors.full_messages.join(', ')}, status: 400 and return
        end
      end

      private

      def find_search
        @search = @current_app_user.search_histories.find_by_id(params[:id])
        render json: {message: "Invalid Search ID"}, status: 422 and return if @search.blank?
      end

      def save_search_params
        permitted = params.permit(:name)
        permitted.merge(search_params: params[:search_params])
      end

    end
  end
end