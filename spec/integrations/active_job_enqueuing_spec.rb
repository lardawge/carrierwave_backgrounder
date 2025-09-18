require 'rails_helper'
require 'support/shared_examples_for_sidekiq_queues'

RSpec.describe 'ActiveJob Enqueuing process', sidekiq_queues: true, clear_images: true do
  subject(:enqueue) { admin.update(documents: load_files('test-1.pdf', type: :document)) }
  let(:admin) { Admin.new }

  after do
    queue_as nil
  end

  after(:all) do
    reset_initializer_and_models(:admin)
  end

  context '>> without globally-configured queue name' do
    before do
      reconfigure_backend(:admin) do |c|
        c.backend :active_job
      end
    end

    context '>> without overridden worker' do
      subject(:enqueue) { admin.update(avatar: load_file('test-1.jpg')) }

      it_behaves_like 'default queue'
    end

    context '>> with overridden worker' do
      context '>> without worker-configured queue name' do
        it_behaves_like 'unset queue'
      end

      context '>> with worker-configured queue name' do
        context '>> with queue name configured as a string/symbol' do
          context '>> set to nil' do
            # :queue_as turns nil into 'default' during `queue_name_from_part` method call
            before { queue_as nil }
            it_behaves_like 'unset queue'
          end

          context '>> set to "default"' do
            before { queue_as 'default' }
            it_behaves_like 'unset queue'
          end

          context '>> set to anything but "default" or nil' do
            before { queue_as worker_queue_name }
            it_behaves_like 'worker queue'
          end
        end

        context '>> with queue name configured as a block' do
          context '>> set to nil' do
            let(:queue_name) { nil }

            before do
              scoped_queue_name = queue_name
              queue_as { scoped_queue_name }
            end

            it_behaves_like 'unset queue'
          end

          context '>> set to "default"' do
            let(:queue_name) { 'default' }

            before do
              scoped_queue_name = queue_name
              queue_as { scoped_queue_name }
            end

            it_behaves_like 'unset queue'
          end

          context '>> set to anything but "default" or nil' do
            before do
              scoped_queue_name = worker_queue_name
              queue_as { scoped_queue_name }
            end

            it_behaves_like 'worker queue'
          end
        end
      end
    end
  end

  context '>> with globally-configured queue name' do
    before do
      reconfigure_backend(:admin) do |c|
        c.backend :active_job, queue: global_queue_name.to_sym
      end
    end

    context '>> without overridden worker' do
      # AvatarUploader doesn't have an overridden worker
      subject(:enqueue) { admin.update(avatar: load_file('test-1.jpg')) }

      # .configure sets :queue_as on the default worker class to `global_queue_name`.
      it_behaves_like 'global queue'
    end

    # CarrierWave::Backgrounder.configure sets :queue_as on its default worker class,
    # so in terms of actual configuration this worker's :queue_as overrides global setting
    context '>> with overridden worker' do
      context '>> without worker-configured queue name' do
        it_behaves_like 'global queue'
      end

      context '>> with worker-configured queue name' do
        context '>> with queue name configured as a string/symbol' do
          context '>> set to nil' do
            before { queue_as nil }

            it_behaves_like 'global queue'
          end

          context '>> set to "default"' do
            before { queue_as 'default' }

            it_behaves_like 'global queue'
          end

          context '>> set to anything but "default" or nil' do
            before { queue_as worker_queue_name }

            it_behaves_like 'worker queue'
          end
        end

        context '>> with queue name configured as a block' do
          context '>> set to nil' do
            let(:queue_name) { nil }

            before do
              scoped_queue_name = queue_name
              queue_as { scoped_queue_name }
            end

            it_behaves_like 'unset queue'
          end

          context '>> set to "default"' do
            let(:queue_name) { 'default' }

            before do
              scoped_queue_name = queue_name
              queue_as { scoped_queue_name }
            end

            it_behaves_like 'unset queue'
          end

          context '>> set to anything but "default" or nil' do
            before do
              scoped_queue_name = worker_queue_name
              queue_as { scoped_queue_name }
            end

            it_behaves_like 'worker queue'
          end
        end
      end
    end
  end

  # ActiveJob::QueueName.queue_as sets :queue_name class_atribute to either a block,
  # or a string comprised of a queue prefix, a delimiter and a queue name.
  # When used with a block, it allows to dynamically set the queue name based on the job arguments.
  describe 'ActiveJob\'s :queue_as' do
    context '>> as string/symbol' do
      subject(:enqueue) { DocumentUploaderActiveJob.perform_later }
      before { queue_as worker_queue_name }

      it_behaves_like 'worker queue'
    end

    context '>> as block' do
      context '>> with context arguments' do
        subject(:enqueue) { DocumentUploaderActiveJob.perform_later(*arguments) }
        let(:arguments) { ['DocumentUploader', 1, 'documents'] }

        it 'allows :queue_as as a block with access to arguments' do
          scoped_queue_name = worker_queue_name
          scoped_arguments = []

          queue_as do
            scoped_arguments = self.arguments.dup
            scoped_queue_name
          end

          sidekiq_queue = Sidekiq::Queues[worker_queue_name]
          expect { enqueue }.to change { sidekiq_queue.size }.from(0).to(1)
          expect(scoped_arguments).to eql(arguments)
        end
      end

      context '>> without context arguments' do
        subject(:enqueue) { DocumentUploaderActiveJob.perform_later }

        before do
          scoped_queue_name = worker_queue_name
          queue_as { scoped_queue_name }
        end

        it_behaves_like 'worker queue'
      end
    end
  end

  # A way to change :queue_as on the fly without creating a separate Job for each case
  def queue_as(...)
    DocumentUploaderActiveJob.class_eval do
      queue_as(...)
    end
  end
end
