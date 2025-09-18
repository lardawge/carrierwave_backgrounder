require 'rails_helper'
require 'support/shared_examples_for_sidekiq_queues'

RSpec.describe 'Sidekiq Enqueuing process', sidekiq_queues: true, clear_images: true do
  shared_examples 'misconfigured job' do
    it 'raises ArgumentError' do
      expect { subject }.to raise_error(ArgumentError)
    end
  end

  subject(:enqueue) { user.update(documents: load_files('test-1.pdf', type: :document)) }
  let(:user) { User.new }

  after do
    sidekiq_options queue: nil
  end

  after(:all) do
    reset_initializer_and_models(:user)
  end

  context '>> without globally-configured queue name' do
    before do
      reconfigure_backend(:user) do |c|
        c.backend :sidekiq
      end
    end

    context '>> without overridden worker' do
      subject(:enqueue) { user.update(avatar: load_file('test-1.jpg')) }

      it_behaves_like 'unset queue'
    end

    context '>> with overridden worker' do
      context '>> without worker-configured queue name' do
        it_behaves_like 'misconfigured job'
      end

      context '>> with worker-configured queue name' do
        context '>> set to nil' do
          before { sidekiq_options queue: nil }

          it_behaves_like 'misconfigured job'
        end

        context '>> set to "default"' do
          before { sidekiq_options queue: 'default' }
          it_behaves_like 'unset queue'
        end

        context '>> not set to "default"' do
          before { sidekiq_options queue: worker_queue_name }
          it_behaves_like 'worker queue'
        end
      end
    end
  end

  context '>> with globally-configured queue name' do
    before do
      reconfigure_backend(:user) do |c|
        c.backend :sidekiq, queue: global_queue_name.to_sym
      end
    end

    context '>> without overridden worker' do
      subject(:enqueue) { user.update(avatar: load_file('test-1.jpg')) }

      it_behaves_like 'global queue'
    end

    context '>> with overridden worker' do
      context '>> without worker-configured queue name' do
        it_behaves_like 'global queue'
      end

      context '>> with worker-configured queue name' do
        context '>> set to nil' do
          before { sidekiq_options queue: nil }

          it_behaves_like 'global queue'
        end

        context '>> set to "default"' do
          before { sidekiq_options queue: 'default' }

          it_behaves_like 'global queue'
        end

        context '>> set to anything but "default" or nil' do
          before { sidekiq_options queue: worker_queue_name }

          it_behaves_like 'worker queue'
        end
      end
    end
  end

  # A way to change :sidekiq_options on the fly
  def sidekiq_options(opts = {})
    DocumentUploaderSidekiqJob.class_eval do
      sidekiq_options(opts)
    end
  end
end
