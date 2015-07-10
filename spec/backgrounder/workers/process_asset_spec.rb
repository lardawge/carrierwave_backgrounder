# encoding: utf-8
require 'spec_helper'
require 'backgrounder/workers/process_asset'

RSpec.describe CarrierWave::Workers::ProcessAsset do
  let(:worker_class) { CarrierWave::Workers::ProcessAsset }
  let(:user)   { double('User') }
  let!(:worker) { worker_class.new(user, '22', :image) }

  describe ".perform" do
    it 'creates a new instance and calls perform' do
      args = [user, '22', :image]
      expect(worker_class).to receive(:new).with(*args).and_return(worker)
      expect_any_instance_of(worker_class).to receive(:perform)

      worker_class.perform(*args)
    end
  end

  describe "#perform" do
    let(:image)  { double('UserAsset') }

    before do
      allow(user).to receive(:find).with('22').and_return(user).once
      allow(user).to receive(:image).twice.and_return(image)
      allow(user).to receive(:process_image_upload=).with(true).once
      allow(image).to receive(:recreate_versions!).once.and_return(true)
    end

    it 'processes versions with image_processing column' do
      expect(user).to receive(:respond_to?).with(:image_processing).once.and_return(true)
      expect(user).to receive(:update_attribute).with(:image_processing, false).once
      worker.perform
    end

    it 'processes versions without image_processing column' do
      expect(user).to receive(:respond_to?).with(:image_processing).once.and_return(false)
      expect(user).to receive(:update_attribute).never
      worker.perform
    end
  end

  describe '#perform with args' do
    let(:admin) { double('Admin') }
    let(:avatar)  { double('AdminAsset') }
    let(:worker) { worker_class.new }

    before do
      allow(admin).to receive(:find).with('23').and_return(admin).once
      allow(admin).to receive(:avatar).twice.and_return(avatar)
      allow(admin).to receive(:process_avatar_upload=).with(true).once
      allow(admin).to receive(:respond_to?).with(:avatar_processing).once.and_return(false)
      allow(avatar).to receive(:recreate_versions!).once.and_return(true)

      worker.perform admin, '23', :avatar
    end

    it 'sets klass' do
      expect(worker.klass).to eql(admin)
    end

    it 'sets column' do
      expect(worker.id).to eql('23')
    end

    it 'sets id' do
      expect(worker.column).to eql(:avatar)
    end
  end
end
