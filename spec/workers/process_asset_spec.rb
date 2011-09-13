# encoding: utf-8
require 'spec_helper'
require 'backgrounder/workers/process_asset'

describe CarrierWave::Workers::ProcessAsset do
  let(:worker_class) { CarrierWave::Workers::ProcessAsset }
  let(:user)   { mock('User') }
  let(:image)  { mock('UserAsset') }
  let!(:worker) { worker_class.new(user, '22', :image) }

  context ".perform" do
    it 'creates a new instance and calls perform' do
      args = [user, '22', :image]
      worker_class.expects(:new).with(*args).returns(worker)
      worker_class.any_instance.expects(:perform)

      worker_class.perform(*args)
    end
  end

  context "#perform" do
    it 'processes versions' do
      user.expects(:find).with('22').returns(user).once
      user.expects(:image).once.returns(image)
      user.expects(:process_image_upload=).with(true).once

      image.expects(:recreate_versions!).once.returns(true)
      user.expects(:respond_to?).with(:image_processing).once.returns(true)
      user.expects(:update_attribute).with(:image_processing, nil).once

      worker.perform
    end
  end
end
