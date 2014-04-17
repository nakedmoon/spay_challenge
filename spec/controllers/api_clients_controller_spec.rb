require 'spec_helper'

describe ApiClientsController do

  it "assigns @api_client and render new" do
    get :new
    api_client = assigns(:api_client)
    expect(api_client).to be_a(ApiClient)
    expect(response).to render_template("new")
  end

  it "create invalid @api_client without uid" do
    post :create, :api_client => {uid: nil, pub0: nil, response_page: nil}
    api_client = assigns(:api_client)
    expect(api_client).to be_a(ApiClient)
    expect(api_client).to be_invalid
    expect(api_client).to have(1).errors_on(:uid)
    expect(response).to render_template("new") # show form with errors
  end

  it "create invalid @api_client with non numeric response_page" do
    post :create, :api_client => {uid: 'player1', pub0: nil, response_page: 'not_a_number'}
    api_client = assigns(:api_client)
    expect(api_client).to be_a(ApiClient)
    expect(api_client).to be_invalid
    expect(api_client).to have(1).errors_on(:response_page)
    expect(response).to render_template("new") # show form with errors
  end

  it "render api_response if sumbit " do
    post :create, :api_client => {uid: 'player1', pub0: nil, response_page: 1}
    api_client = assigns(:api_client)
    expect(api_client).to be_a(ApiClient)
    expect(api_client).to be_valid
    expect(response).to render_template("api_response")
  end

end
