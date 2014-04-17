require 'spec_helper'

describe ApiClient do

  it "is valid passing at least uid" do
    expect(Fabricate(:api_client)).to be_valid
  end

  it "is invalid without uid" do
    expect(Fabricate(:api_client, :uid => nil)).to be_invalid
  end

  it "is invalid without url" do
    expect(Fabricate(:api_client, :url => nil)).to be_invalid
  end

  it "is invalid without key" do
    expect(Fabricate(:api_client, :key => nil)).to be_invalid
  end

  it "is invalid without appid" do
    expect(Fabricate(:api_client, :appid => nil)).to be_invalid
  end

  it "is invalid without device_id" do
    expect(Fabricate(:api_client, :device_id => nil)).to be_invalid
  end

  it "is invalid without offer_descriptions_locale" do
    expect(Fabricate(:api_client, :offer_descriptions_locale => nil)).to be_invalid
  end

  it "is invalid when response_page is not a number" do
    expect(Fabricate(:api_client, :response_page => 'not_a_number')).to be_invalid
  end

  it "is invalid when offer_types_filter is not a number in the list" do
    expect(Fabricate(:api_client, :offer_types_filter => 99)).to be_invalid
  end

  it "is invalid with response_format different from json or xml" do
    expect(Fabricate(:api_client, :response_format => :html)).to be_invalid
  end

  it "hashkey is not null after saving" do
    api_client = Fabricate(:api_client)
    expect(api_client.save).to be_true
    expect(api_client.hashkey).not_to be_nil
  end

  it "has a valid response object after save" do
    api_client = Fabricate(:api_client)
    expect(api_client.save).to be_true
    api_response = api_client.response
    expect(api_response).to be_a(ApiResponse)
  end

  it "response ERROR_INVALID_PAGE if invalid page nummber sumbitted" do
    api_client = Fabricate(:api_client, :device_id => 'my_device')
    expect(api_client.save).to be_true
    api_response = api_client.response
    api_response_total_pages = api_response.pages
    expect(api_response_total_pages).to be >0 # total pages >= 0
    # New request getting a page number invalid
    new_page_number = api_response_total_pages + 1
    api_client = Fabricate(:api_client, :response_page => new_page_number)
    expect(api_client.response_page).to eq(new_page_number)
    expect(api_client.save).to be_true
    api_response = api_client.response
    expect(api_response.code).to eq('ERROR_INVALID_PAGE')
  end


  it "response ERROR_INVALID_HASHKEY if initialize with invalid key" do
    api_client = Fabricate(:api_client, :key => 'invalid_key')
    expect(api_client.key).to eq('invalid_key')
    expect(api_client.save).to be_true
    api_response = api_client.response
    expect(api_response.code).to eq('ERROR_INVALID_HASHKEY')
  end

  it "response JSON/PARSER_ERROR if initialize with invalid url" do
    api_client = Fabricate(:api_client, :url => 'http://www.google.it')
    expect(api_client.url).to eq('http://www.google.it')
    expect(api_client.save).to be_true
    api_response = api_client.response
    expect(api_response.code).to eq('JSON/PARSER_ERROR')
  end

  it "response ERROR_INVALID_APPID if initialize with invalid appid" do
    api_client = Fabricate(:api_client, :appid => 'invalid_app_id')
    expect(api_client.save).to be_true
    api_response = api_client.response
    expect(api_response.code).to eq('ERROR_INVALID_APPID')
  end


  it "response count match with offers array size" do
    api_client = Fabricate(:api_client, :device_id => 'my_device')
    expect(api_client.save).to be_true
    api_response = api_client.response
    expect(api_response.offers.class).to be Array
    expect(api_response.offers.count).to eq(api_response.count)
  end













end


