require 'rails_helper'

RSpec.describe 'Queue Name', clear_images: true do
  let(:user) { User.new }

  context 'when using built in worker' do
    context 'when queue name is passed in via config' do
      before do
        CarrierWave::Backgrounder.instance_variable_set(:@queue_options, queue: 'carrierwaver')
      end

      after do
        CarrierWave::Backgrounder.instance_variable_set(:@queue_options, queue: 'carrierwave')
      end

      it 'uses the config queue name' do
        user.update(avatar: load_file('test-1.jpg'))
        expect(Sidekiq::Queues["carrierwaver"].size).to eql(1)
      end
    end

    context 'when not queue name is not set' do
      it 'uses the default name carrierwave' do
        user.update(avatar: load_file('test-1.jpg'))
        expect(Sidekiq::Queues["carrierwave"].size).to eql(1)
      end
    end
  end

  context 'when using a subclassed worker' do
    context 'when queue name is passed in via config' do
      before do
        CarrierWave::Backgrounder.instance_variable_set(:@queue_options, queue: 'carrierwaver')
      end

      after do
        CarrierWave::Backgrounder.instance_variable_set(:@queue_options, queue: 'carrierwave')
      end

      it 'uses the config queue name' do
        user.update(portrait: load_file('test-1.jpg'))
        expect(Sidekiq::Queues["carrierwaver"].size).to eql(1)
      end
    end

    context 'when not queue name is not set' do
      it 'uses the default name carrierwave' do
        user.update(portrait: load_file('test-1.jpg'))
        expect(Sidekiq::Queues["carrierwave"].size).to eql(1)
      end
    end

    context 'when overridden via subclassed worker' do
      before do
        PortraitProcessJob.queue_as :custom_queue
      end

      after do
        PortraitProcessJob.queue_as :carrierwave
      end

      it 'uses the queue name passed in' do
        user.update(portrait: load_file('test-1.jpg'))
        expect(Sidekiq::Queues["custom_queue"].size).to eql(1)
      end
    end
  end
end