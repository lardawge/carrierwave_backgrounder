require 'rails_helper'

RSpec.describe '::store_in_background', clear_images: true do
  let(:user) { User.new }

  context 'when assigning an asset' do
    before(:each) do
      expect(file_count('spec/support/dummy_app/tmp/images')).to eql(0)
      user.avatar = load_file('spec/support/fixtures/images/test-1.jpg')
      user.save
    end

    it 'creates a temp file and stores the path' do
      expect(file_count('spec/support/dummy_app/tmp/images')).to eql(1)
      expect(user.avatar_tmp).to include('test-1.jpg')
    end

    it 'creates a background job in carrierwave queue' do
      expect(Sidekiq::Queues["carrierwave"].size).to eql(1)
    end
  end

  context 'when saving a record' do
    let!(:user) {
      Sidekiq::Testing.inline! do
        User.create(avatar: load_file('spec/support/fixtures/images/test-1.jpg'))
      end
    }

    it 'does not enqueue a new job' do
      expect { user.reload.save }.to_not change(Sidekiq::Queues["carrierwave"], :size)
    end
  end
end