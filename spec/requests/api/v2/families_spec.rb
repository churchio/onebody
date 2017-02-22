require_relative '../../../rails_helper'

describe 'Families API', type: :request do
  let!(:application) { FactoryGirl.create(:oauth_application) }
  let!(:token)       { FactoryGirl.create(:oauth_access_token, application: application) }

  it 'should return a list of families' do
    FactoryGirl.create_list(:family, 10)

    get "/api/v2/families", :access_token => token.token

    expect(response).to be_success
    expect(json_data.length).to eq(10)
  end

  it 'should retrieve a specific family' do
    family = FactoryGirl.create(:family)

    get "/api/v2/families/#{family.id}", :access_token => token.token

    expect(response).to be_success
    expect(json_data['id'].to_i).to eq(family.id)
    expect(json_attributes['name']).to eq(family.name)
  end

  it 'should return the family members' do
    family = FactoryGirl.create(:family)
    FactoryGirl.create_list(:person, 5, family: family)

    get "/api/v2/families/#{family.id}/people", :access_token => token.token

    expect(response).to be_success
    expect(json_data.length).to eq(5)
    expect(json_data[0]['type']).to eq('people')
  end
end