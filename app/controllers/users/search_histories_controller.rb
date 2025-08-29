module Users
  class SearchHistoriesController < ApplicationController
    before_action :set_histories
    before_action :set_history, only: [:destroy]

    respond_to :html

    def index
    end

    def destroy
      if @history.destroy
        flash[:success] = "Deleted Successfully"
      else
        flash[:danger] = "Cannot delete search history - #{@history.errors.full_messages.join(', ')}"
      end
      redirect_to users_search_histories_path and return
    end

    private
      def set_history
        @history = @histories.find(params[:id])
      end

      def set_histories
        @histories = current_user.search_histories
      end
  end
end