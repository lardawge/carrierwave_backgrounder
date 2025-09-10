require 'spec_helper'
require 'support/mock_worker'

module CarrierWave::Backgrounder
  RSpec.describe Support::Backends do
    let(:mock_module) { Module.new }

    before do
      mock_module.send :include, Support::Backends
    end

    describe 'setting backend' do
      it 'using #backend=' do
        expect {
          mock_module.backend = :delayed_job
        }.to raise_error(NoMethodError)
      end

      it 'using #backend' do
        mock_module.backend(:delayed_job)
        expect(mock_module.backend).to eql(:delayed_job)
      end

      it 'allows passing of queue_options' do
        mock_module.backend(:delayed_job, :queue => :awesome_queue)
        expect(mock_module.queue_options).to eql({:queue => :awesome_queue})
      end
    end

    describe '#enqueue_for_backend' do
      let!(:worker) { MockWorker.new('FakeClass', 1, :image) }

      context 'active_job' do
        let(:args) { ['FakeClass', 1, :image] }

        it 'invokes perform_later with string arguments' do
          expect(MockActiveJob).to receive(:perform_later).with('FakeClass', '1', 'image')
          mock_module.backend :active_job
          mock_module.enqueue_for_backend(MockActiveJob, *args)
        end

        describe 'queue name configuration' do
          #    config    worker      result
          #      0         0      'carrierwave'
          #      1         0         config
          #      1         1         worker (must use a block for 'default')
          #      0         1         worker
          context 'queue name configured globally' do
            let(:queue_options) { { :queue => :global_queue } }

            it 'uses globally configured queue name' do
              expect(MockActiveJob).to receive(:set).with(queue_options).and_return(MockActiveJob)

              mock_module.backend :active_job, queue_options
              mock_module.enqueue_for_backend(MockActiveJob, *args)
            end

            context 'and queue name is configured in worker' do
              it 'uses worker-configured queue' do
                worker_queue = :worker_queue
                allow(MockActiveJob).to receive(:queue_name).and_return(worker_queue)

                expect(MockActiveJob).to receive(:set).with({ :queue => worker_queue }).and_return(MockActiveJob)
                mock_module.backend :active_job, queue_options
                mock_module.enqueue_for_backend(MockActiveJob, *args)
              end

              it 'uses worker-configured queue set as a string' do
                worker_queue_str = 'worker_queue'
                allow(MockActiveJob).to receive(:queue_name).and_return(worker_queue_str)

                expect(MockActiveJob).to receive(:set).with({ :queue => worker_queue_str }).and_return(MockActiveJob)
                mock_module.backend :active_job, queue_options
                mock_module.enqueue_for_backend(MockActiveJob, *args)
              end

              it 'uses worker-configured queue set as a block' do
                worker_queue_block = Proc.new { 'any_queue' }
                allow(MockActiveJob).to receive(:queue_name).and_return(worker_queue_block)

                expect(MockActiveJob).to receive(:set).with({ :queue => worker_queue_block }).and_return(MockActiveJob)
                mock_module.backend :active_job, queue_options
                mock_module.enqueue_for_backend(MockActiveJob, *args)
              end

              it 'ignores the `queue_as \'default\'` set as a string' do
                default_string = 'default'
                allow(MockActiveJob).to receive(:queue_name).and_return(default_string)

                expect(MockActiveJob).to receive(:set).with(queue_options).and_return(MockActiveJob)
                mock_module.backend :active_job, queue_options
                mock_module.enqueue_for_backend(MockActiveJob, *args)
              end

              it 'allows to force "default" queue in worker with a block' do
                default_block = Proc.new { 'default' }
                allow(MockActiveJob).to receive(:queue_name).and_return(default_block)

                expect(MockActiveJob).to receive(:set).with({ :queue => default_block }).and_return(MockActiveJob)
                mock_module.backend :active_job, queue_options
                mock_module.enqueue_for_backend(MockActiveJob, *args)
              end
            end
          end

          context 'queue name is configured in worker' do
            it 'uses worker-configured queue' do
              allow(MockActiveJob).to receive(:queue_name).and_return(:awesome_queue)

              expect(MockActiveJob).to receive(:set).with({ :queue => :awesome_queue }).and_return(MockActiveJob)
              mock_module.backend :active_job
              mock_module.enqueue_for_backend(MockActiveJob, *args)
            end
          end

          context 'queue name is not configured' do
            it 'uses "carrierwave" queue' do
              expect(MockActiveJob).to receive(:set).with({ :queue => 'carrierwave' }).and_return(MockActiveJob)
              mock_module.backend :active_job, {}
              mock_module.enqueue_for_backend(MockActiveJob, *args)
            end
          end
        end
      end

      context 'sidekiq' do
        let(:args) { ['FakeClass', 1, :image] }

        it 'invokes client_push on the class with passed args' do
          expect(MockSidekiqWorker).to receive(:client_push).with({ 'class' => MockSidekiqWorker, 'args' => args.map(&:to_s) })
          mock_module.backend :sidekiq
          mock_module.enqueue_for_backend(MockSidekiqWorker, *args)
        end

        it 'invokes client_push and includes the options passed to backend' do
          expect(MockSidekiqWorker).to receive(:client_push).with({ 'class' => MockSidekiqWorker,
                                                                    'retry' => false,
                                                                    'timeout' => 60,
                                                                    'queue' => :awesome_queue,
                                                                    'args' => args.map(&:to_s) })
          options = {:retry => false, :timeout => 60, :queue => :awesome_queue}
          mock_module.backend :sidekiq, options
          mock_module.enqueue_for_backend(MockSidekiqWorker, *args)
        end

        it 'does not override queue name if set it worker' do
          expect(MockNamedSidekiqWorker).to receive(:client_push).with({ 'class' => MockNamedSidekiqWorker,
                                                                    'retry' => false,
                                                                    'timeout' => 60,
                                                                    'args' => args.map(&:to_s) })
          options = {:retry => false, :timeout => 60}
          mock_module.backend :sidekiq, options
          mock_module.enqueue_for_backend(MockNamedSidekiqWorker, *args)
        end
      end
    end
  end
end
