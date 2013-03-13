module Support
  module Backends

    def self.included(base)
      base.extend ClassMethods
    end

    module ClassMethods
      attr_reader :queue_options

      def backend(queue_name=nil, args={})
        return @backend if @backend
        @queue_options = args
        @backend = queue_name
      end

      def enqueue_for_backend(worker, class_name, subject_id, mounted_as)
        self.send :"enqueue_#{backend}", worker, class_name, subject_id, mounted_as
      end

      private

      def enqueue_delayed_job(worker, *args)
        ::Delayed::Job.enqueue worker.new(*args), :queue => queue_options[:queue]
      end

      def enqueue_resque(worker, *args)
        worker.instance_variable_set('@queue', queue_options[:queue] || :carrierwave)
        ::Resque.enqueue worker, *args
      end

      def enqueue_sidekiq(worker, *args)
        sidekiq_client_args = { 'class' => worker, 'args' => args }
        sidekiq_client_args['queue'] = queue_options[:queue] unless queue_options[:queue].nil?
        sidekiq_client_args['retry'] = queue_options[:retry] unless queue_options[:retry].nil?
        sidekiq_client_args['timeout'] = queue_options[:timeout] unless queue_options[:timeout].nil?
        sidekiq_client_args['backtrace'] = queue_options[:backtrace] unless queue_options[:backtrace].nil?
        worker.client_push(sidekiq_client_args)
      end

      def enqueue_girl_friday(worker, *args)
        @girl_friday_queue ||= GirlFriday::WorkQueue.new(queue_options.delete(:queue) || :carrierwave, queue_options) do |msg|
          worker = msg[:worker]
          worker.perform
        end
        @girl_friday_queue << { :worker => worker.new(*args) }
      end

      def enqueue_sucker_punch(worker, *args)
        @sucker_punch_queue ||= SuckerPunch::Queue[queue_options.delete(:queue) || :carrierwave]
        @sucker_punch_queue.async.perform(*args)
      end

      def enqueue_qu(worker, *args)
        worker.instance_variable_set('@queue', queue_options[:queue] || :carrierwave)
        ::Qu.enqueue worker, *args
      end

      def enqueue_qc(worker, *args)
        class_name, subject_id, mounted_as = args
        ::QC.enqueue "#{worker.name}.perform", class_name, subject_id, mounted_as.to_s
      end

      def enqueue_immediate(worker, *args)
        worker.new(*args).perform
      end
    end
  end
end
