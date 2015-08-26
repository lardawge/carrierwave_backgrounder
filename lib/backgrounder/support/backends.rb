module CarrierWave
  module Backgrounder
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
            worker_args = {}
            if ::Delayed::Job.new.respond_to?(:queue)
              worker_args[:queue] = queue_options[:queue] if queue_options[:queue]
              worker_args[:priority] = queue_options[:priority] if queue_options[:priority]
              ::Delayed::Job.enqueue worker.new(*args), worker_args
            else
              worker_args[:priority] = queue_options[:priority] if queue_options[:priority]
              ::Delayed::Job.enqueue worker.new(*args), worker_args
              if queue_options[:queue]
                ::Rails.logger.warn("Queue name given but no queue column exists for Delayed::Job")
              end
            end
          end

          def enqueue_resque(worker, *args)
            worker.instance_variable_set('@queue', queue_options[:queue] || :carrierwave)
            ::Resque.enqueue worker, *args
          end

          def enqueue_sidekiq(worker, *args)
            override_queue_name = worker.sidekiq_options['queue'] == 'default' || worker.sidekiq_options['queue'].nil?
            args = sidekiq_queue_options(override_queue_name, 'class' => worker, 'args' => args)
            worker.client_push(args)
          end

          def enqueue_girl_friday(worker, *args)
            @girl_friday_queue ||= GirlFriday::WorkQueue.new(queue_options.delete(:queue) || :carrierwave, queue_options) do |msg|
              worker = msg[:worker]
              worker.perform
            end
            @girl_friday_queue << { :worker => worker.new(*args) }
          end

          def enqueue_sucker_punch(worker, *args)
            worker.new.async.perform(*args)
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

          def sidekiq_queue_options(override_queue_name, args)
            if override_queue_name && queue_options[:queue]
              args['queue'] = queue_options[:queue]
            end
            args['retry'] = queue_options[:retry] unless queue_options[:retry].nil?
            args['timeout'] = queue_options[:timeout] if queue_options[:timeout]
            args['backtrace'] = queue_options[:backtrace] if queue_options[:backtrace]
            args
          end
        end
      end
    end
  end
end
