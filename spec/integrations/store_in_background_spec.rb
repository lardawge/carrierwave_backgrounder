require 'rails_helper'

RSpec.describe '::store_in_background', images: true do
  let(:user) { User.new }

  it 'creates a temp file and stores the path' do
    expect {
      user.update(avatar: File.open('spec/support/fixtures/images/test-1.jpg')) 
    }.to change { Dir.entries('spec/support/dummy_app/tmp/images').size }.by(1)

    expect(user.avatar_tmp).to include('test-1.jpg')
  end

  it 'creates a background job in queue'
end