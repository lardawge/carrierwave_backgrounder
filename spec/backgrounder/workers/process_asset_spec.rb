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
    let(:file)   { mock('ImageFile') }

    before do
      user.expects(:find).with('22').returns(user).once
      # First to check file exist, second to call recreate_versions!
      user.expects(:image).twice.returns(image)
      user.expects(:process_image_upload=).with(true).once
      image.expects(:recreate_versions!).once.returns(true)
      image.expects(:file).once.returns(file)
      file.expects(:present?).once.returns(true)
    end

    it 'processes versions with image_processing column' do
      user.expects(:respond_to?).with(:image_processing).once.returns(true)
      user.expects(:update_attribute).with(:image_processing, false).once
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
    let(:file) { mock('AvatarFile') }
    let(:worker) { worker_class.new }

    describe "when asset file is present" do
      before do
        admin.expects(:find).with('23').returns(admin).once
        # First to check file exist, second to call recreate_versions!
        admin.expects(:avatar).twice.returns(avatar)
        admin.expects(:process_avatar_upload=).with(true).once
        admin.expects(:respond_to?).with(:avatar_processing).once.returns(false)
        avatar.expects(:recreate_versions!).once.returns(true)
        avatar.expects(:file).once.returns(file)
        file.expects(:present?).once.returns(true)

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

    describe "when asset file is missing" do
      before do
        admin.expects(:find).with('23').returns(admin).once
        admin.expects(:avatar).once.returns(avatar)
        avatar.expects(:file).once.returns(file)
        file.expects(:present?).once.returns(false)
        # recreate_versions! should not be called

        worker.perform admin, '23', :avatar
      end

      it 'sets klass' do
        expect(worker.klass).to eql(admin)
      end
    end
  end
end
