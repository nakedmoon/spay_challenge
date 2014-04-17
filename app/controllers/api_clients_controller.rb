class ApiClientsController < ApplicationController


  def new
    @api_client = ApiClient.new
  end

  def create
    @api_client = ApiClient.new(api_client_params)

    respond_to do |format|
      if @api_client.save
        format.html { render 'api_response' }
        format.json { render :text => @api_client.to_json, status: :created }
      else
        format.html { render action: 'new' }
        format.json { render json: @api_client.errors, status: :unprocessable_entity }
      end
    end
  end

  private

    def api_client_params
      params.require(:api_client).permit(:uid, :pub0, :response_page)
    end






end
