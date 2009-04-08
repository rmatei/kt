# Kontagent facebooker version 0.2.0
require 'kt/queue/processor'
require 'kt/kt_comm_layer'

class RecordProcessor < Kt::Queue::Processor
  def process
    op = options
    qtype = op[:qtype]
    if qtype == :kt_outbound
      m_comm = Kt::KtComm.instance(op[:kt_call_back_host], op[:kt_call_back_port])
      m_comm.api_call_method(op[:kt_url], op[:v], op[:kt_api_key], op[:kt_secret_key], op[:ctype], op[:arg_hash])
    elsif qtype == :capture_user_data
      Kt::KtAnalytics.instance.send_user_data_impl(Marshal.load(op[:user]))
    end
  end
end

module Kt
  module Queue
    class Task    
      MAX_ERRORS = 3

      attr_reader :options
    
      def process!
        processor.new.process!(self)
      end
    
      # Puts a failed Task back in the Queue with the lowest priority.
      # If a task fails MAX_ERRORS times, it is put in Queue 0 which is never processed.
      def enqueue_with_error(e)
        @options[:failures] = @options[:failures].to_i + 1
        @options[:errors] ||= []
      
        @options[:priority] = (@options[:failures] < MAX_ERRORS) ? 10 : 0
        Kt::Queue::Queue.enqueue(@options[:priority], @options.merge!({
          :action => @action,
          :errors => @options[:errors] << {:class => e.class.to_s, :message => e.message}
        }))
      
        Kt::Queue::Queue.log("Action '#{@action}' failed #{@options[:failures]} time(s).")
      
        # Send failure notification if a notification observer is defined
        if @options[:priority] == 0 && Kt::Queue::Queue.failure_notification_observer
          Kt::Queue::Queue.failure_notification_observer.call(self, e)
        end
      end

      # Puts actions in the Queue. Priority defaults to 5
      def self.publish(action, options={})
        priority = options[:priority] || 5
        options.merge!({:action => action})
        Kt::Queue::Queue.enqueue(priority, options)
      end
    
      # Creates a Task from a message
      def self.from_message(message)
        action = message.delete :action
        Task.new(action, message)
      end
    
      def initialize(action, options = {})
        @action = action
        @options = {:priority => 5}.merge(options)
      end
    
      protected
        # Infers a Processor's name from the action
      
      def processor
        Object.const_get(@action.to_s.camelize + 'Processor')
      end
    end
    
  end
end
