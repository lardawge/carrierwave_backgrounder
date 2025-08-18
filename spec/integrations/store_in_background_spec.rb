require 'rails_helper'

RSpec.describe '::store_in_background', clear_images: true do
  let(:user) { User.new }

  context 'when assigning an asset' do
    before(:each) do
      expect(file_count('spec/support/dummy_app/tmp/images')).to eql(0)
      user.update(avatar: load_file('test-1.jpg'))
    end

    it 'creates a temp file and stores the path' do
      expect(file_count('spec/support/dummy_app/tmp/images')).to eql(1)
      expect(user.avatar_tmp).to include('test-1.jpg')
    end

    it 'creates a background job in carrierwave queue' do
      expect(Sidekiq::Queues["carrierwave"].size).to eql(1)
    end

    it 'sets the <column>_processing flag to true' do
      expect(user.avatar_processing).to be(true)
    end
  end

  context 'when processing the worker' do
    before do
      user.update(avatar: load_file('test-1.jpg'))
      expect(user.avatar_processing).to be(true)
      process_latest_sidekiq_job
      user.reload
    end

    it 'processes the original image' do
      image = MiniMagick::Image.open(user.avatar.path)
      expect(image.width).to eql(1960)
    end

    it 'creates the versions' do
      version_paths = user.avatar.versions.keys.map { |key| user.avatar.send(key).current_path }
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
        User.create(avatar: load_file('test-1.jpg'))
      end
    }

    it 'does not enqueue a new job' do
      expect { user.reload.save }.to_not change(Sidekiq::Queues["carrierwave"], :size)
    end
  end

  context 'when a record gets deleted before it is processed' do
    context 'and suppress_record_not_found_errors is set to true' do
      before do
        user.update(avatar: load_file('test-1.jpg'))
      end

      it 'does not raise an error' do
        user.delete
        expect { process_latest_sidekiq_job }.not_to raise_error
      end
    end

    context 'and suppress_record_not_found_errors is set to false' do
      before do
        user.update(avatar: load_file('test-1.jpg'))
        CarrierWave::Backgrounder.suppress_record_not_found_errors(false)
      end

      after do
        CarrierWave::Backgrounder.suppress_record_not_found_errors(true)
      end

      it 'raises an error' do
        user.delete
        expect { process_latest_sidekiq_job }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  context 'when setting a column for removal' do
    let!(:user) {
      Sidekiq::Testing.inline! do
        User.create(avatar: load_file('test-1.jpg'))
      end
    }

    before do
      expect(user.reload.avatar.file.nil?).to be(false)

      user.remove_avatar = true
      user.save!
    end

    it 'removes the attachment' do
      expect(user.avatar.file.nil?).to be(true)
    end

    it 'does not enqueue a new job' do
      expect(Sidekiq::Queues["carrierwave"].size).to be(0)
    end
  end
end
