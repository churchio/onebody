require_relative '../../../rails_helper'

describe 'Verses API', type: :request do
  let!(:application) { FactoryGirl.create(:oauth_application) }
  let!(:token)       { FactoryGirl.create(:oauth_access_token, application: application) }

  it 'should return a list of verses' do
    FactoryGirl.create_list(:verse, 10)

    get "/api/v2/verses", :access_token => token.token

    expect(response).to be_success
    expect(json_data.length).to eq(10)
  end

  it 'should retrieve a specific verse' do
    verse = FactoryGirl.create(:verse)

    get "/api/v2/verses/#{verse.id}", :access_token => token.token

    expect(response).to be_success
    expect(json_data['id'].to_i).to eq(verse.id)
  end

  it 'should retrieve the comments of a verse' do
    verse = FactoryGirl.create(:verse)
    verse.comments = FactoryGirl.create_list(:comment, 10)


    get "/api/v2/verses/#{verse.id}/comments", :access_token => token.token

    expect(response).to be_success
    expect(json_data.length).to eq(10)
    expect(json_data[0]['type']).to eq('comments')
  end
end