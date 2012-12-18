# encoding: utf-8
require 'spec_helper'
require 'backgrounder/workers/process_asset'

describe CarrierWave::Workers::ProcessAsset do
  let(:worker_class) { CarrierWave::Workers::ProcessAsset }
  let(:user)   { mock('User') }
  let!(:worker) { worker_class.new(user, '22', :image) }

  describe ".perform" do
    it 'creates a new instance and calls perform' do
      args = [user, '22', :image]
      worker_class.expects(:new).with(*args).returns(worker)
      worker_class.any_instance.expects(:perform)

      worker_class.perform(*args)
    end
  end

  describe "#perform" do
    let(:image)  { mock('UserAsset') }

    before do
      user.expects(:find).with('22').returns(user).once
      user.expects(:image).once.returns(image)
      user.expects(:process_image_upload=).with(true).once
      image.expects(:recreate_versions!).once.returns(true)
    end

    it 'processes versions with image_processing column' do
      user.expects(:respond_to?).with(:image_processing).once.returns(true)
      user.expects(:update_attribute).with(:image_processing, nil).once
      worker.perform
    end

    it 'processes versions without image_processing column' do
      user.expects(:respond_to?).with(:image_processing).once.returns(false)
      user.expects(:update_attribute).never
      worker.perform
    end
  end

  describe '#perform with args' do
    let(:admin) { mock('Admin') }
    let(:avatar)  { mock('AdminAsset') }
    let(:worker) { worker_class.new }

    before do
      admin.expects(:find).with('23').returns(admin).once
      admin.expects(:avatar).once.returns(avatar)
      admin.expects(:process_avatar_upload=).with(true).once
      admin.expects(:respond_to?).with(:avatar_processing).once.returns(false)
      avatar.expects(:recreate_versions!).once.returns(true)

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
