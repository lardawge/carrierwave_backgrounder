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
          expect(MockWorker).to receive(:perform_later).with('FakeClass', '1', 'image')
          mock_module.backend :active_job
          mock_module.enqueue_for_backend(MockWorker, *args)
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
