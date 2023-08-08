require 'rails_helper'

RSpec.describe '::store_in_background', clear_images: true do
  let(:user) { User.new }

  before(:each) do
    expect(file_count('spec/support/dummy_app/tmp/images')).to eql(0)
    user.avatar = load_file('spec/support/fixtures/images/test-1.jpg')
    user.save
  end

  it 'creates a temp file and stores the path' do
    expect(file_count('spec/support/dummy_app/tmp/images')).to eql(1)
    expect(user.avatar_tmp).to include('test-1.jpg')
  end

  it 'creates a background job in queue' do

  end
end