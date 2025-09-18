RSpec.shared_examples "Sidekiq queues", sidekiq_queues: true do
  subject(:enqueue) {}

  let(:global_queue_name) { 'global_queue' }
  let(:worker_queue_name) { 'worker_queue' }
  let(:unset_queue_name) { 'default' }

  {
    global: 'globally-configured',
    worker: 'worker-configured',
    default: 'default "carrierwave"',  # GlobalMacros#default_queue_name
    unset: 'worker-configured "default"'
  }.each do |queue, description|
    shared_examples "#{queue} queue" do
      it "uses #{description} queue" do
        queue_name = public_send(:"#{queue}_queue_name")
        sidekiq_queue = Sidekiq::Queues.public_send(:[], queue_name)

        expect { enqueue }.to change { sidekiq_queue.size }.from(0).to(1)
      end
    end
  end
end
