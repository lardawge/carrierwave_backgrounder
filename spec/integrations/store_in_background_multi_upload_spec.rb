require 'rails_helper'

RSpec.describe '::store_in_background multi-upload support', clear_images: true do
  let(:user) { User.new }

  context 'when assigning an asset' do
    before(:each) do
      expect(file_count('spec/support/dummy_app/tmp/images')).to eql(0)
      user.update(images: load_files('test-1.jpg', 'test-2.jpg'))
    end

    it 'creates a temp file and stores the path' do
      expect(file_count('spec/support/dummy_app/tmp/images')).to eql(2)
      expect(user.images_tmp).to include('test-1.jpg')
    end

    it 'creates a background job in carrierwave queue' do
      expect(Sidekiq::Queues["carrierwave"].size).to eql(1)
    end

    it 'sets the <column>_processing flag to true' do
      expect(user.images_processing).to be(true)
    end
  end

  context 'when processing the worker' do
    before do
      user.update(images: load_files('test-1.jpg','test-2.jpg'))
      expect(user.images_processing).to be(true)
      process_latest_sidekiq_job
      user.reload
    end

    it 'creates the versions' do
      version_paths = AvatarUploader.versions.keys.map { |key| user.images.map { |i| i.send(key).current_path } }.flatten
      version_paths.each { |path| expect(File.exist?(path)).to be(true) }
      file_sizes = version_paths.map { |path| File.size(path) }
      expect(file_sizes.uniq.count).to be(4)
    end

    it 'sets the <column>_tmp to nil' do
      expect(user.avatar_tmp).to be_nil
    end

    it 'removes the files tmp directory' do
      expect(file_count('spec/support/dummy_app/tmp/images')).to eql(0)
    end

    it 'sets the <column>_processing flag to false' do
      expect(user.avatar_processing).to be(false)
    end
  end

  context 'when saving a record' do
    let!(:user) {
      Sidekiq::Testing.inline! do
        User.create(images: load_files('test-1.jpg'))
      end
    }

    it 'does not enqueue a new job' do
      expect { user.reload.save }.to_not change(Sidekiq::Queues["carrierwave"], :size)
    end
  end

  context 'when setting a column for removal' do
    let!(:user) {
      Sidekiq::Testing.inline! do
        User.create(images: load_files('test-1.jpg'))
      end
    }

    before do
      expect(user.reload.images.present?).to be(true)

      user.remove_images = true
      user.save!
    end

    it 'removes the attachment' do
      expect(user.images.present?).to be(false)
    end

    it 'does not enqueue a new job' do
      expect(Sidekiq::Queues["carrierwave"].size).to be(0)
    end

  end
end
