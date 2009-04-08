# Kontagent facebooker version 0.2.0
require 'starling'


module Kt
  module Queue
    class Queue
      attr_reader :connection
      
      # Max number of reconnection attempts to starling
      MAX_TRIES = 1

      class << self
        def queue
          @queue ||= Queue.new
        end
      
        def enqueue(priority, message)
          queue.enqueue(priority, message)
        end
      
        def process!
          queue.process!
        end

        def stop!
          queue.stop!
        end
        # Statictics methods
        def count_permanently_failed
          queue.connection.sizeof("#{queue.config['canvas_page_name']}_p_0")
        end
      
        def count
          queue.connection.sizeof(:all).inject(0){|c, (k, v)| c+= v}
        end
      
        # Use this method to see what's in the queue
        def peek(priority, iterate = 1)
          messages = []
        
          iterate.times do
            message = queue.connection.get("#{queue.config['canvas_page_name']}_p_#{priority}")
            enqueue(priority, message)
        
            messages << message
          end
        
          messages
        end
      
        # You can use this method to define an external Proc (usually a lambda) that
        # is sent a notification when a task fails more than the max allowed times.
        # The lambda is passed the Kt::Queue::Task object, and the last Exception object.
        # For example:
        #   Kt::Queue::Queue.failure_notification_observer = lambda {|task, error|
        #     Mailer.deliver_exception_mail(...)
        #   }
        attr_accessor :failure_notification_observer
      end

      def initialize
        self.connect!
      end    
    
      def enqueue(priority, message)
        if message[:action].blank?
          error = "Tried to queue a task with an empty action. The message being queued was: #{message.inspect}"
          Kt::Queue::Queue.log(error, true)
        end
        @current_message = message
        value_with_retries do
          @connection.set("#{config['canvas_page_name']}_p_#{priority}", message)
        end
      end
    
      def dequeue(priority)
        @current_message = nil
        value_with_retries do
          @connection.get("#{config['canvas_page_name']}_p_#{priority}")
        end      
      end
    
      # Loads the config file
      def config
        @config ||= YAML.load_file("#{RAILS_ROOT}/config/kontagent.yml")
      end
    
      # Gets the next_item in the Queue
      def next_item
        result = nil
        
        10.times do |i|
          result = dequeue(i+1)
          break unless result.blank?
        end
        result
      end    
    
      def flush
        10.times do |i|
          result = @connection.flush("#{config['canvas_page_name']}_p_#{i+1}")
        end
      end
    
      # The main loop. It goes like this:
      # 1. Calls process which:
      #   * calls next_item (returns nil or a task from the queue)
      #   * process returns false if next_item is nil
      #   * process creates a new task and calls process! on it
      # 2. The loop continues
      def process!
        @running = true
        while @running
          result = process
    
          unless result
            puts "Waiting..." if RAILS_ENV == "development"
            GC.enable
            GC.start
            sleep 3
          end
        
          sleep 1
        end       
      end
    
      def stop!
        @running = false
      end
    
      def self.log(message, force=false)
        RAILS_DEFAULT_LOGGER.send(force ? :error : :debug, message)
      end
    
      protected
        def connect!
          Kt::Queue::Queue.log "Connecting on #{config['queue_address']}, canvas_page_name: #{config['canvas_page_name']}"
        
          @connection = Starling.new(config['queue_address'])
        end
      
        # Gets an item from the queue if there is one, creates a task, and runs process! on it
        def process
          task = next_item

          Kt::Queue::Queue.log "Running #{task.inspect}..."
                
          task.blank? ? false : Kt::Queue::Task.from_message(task).process! 
        end
      
        def value_with_retries(&block)
          tries = 0
          result = nil

          begin
            result = yield
          rescue MemCache::MemCacheError => e
            Kt::Queue::Queue.log "Try ##{tries} - Starling Error: #{e.class} -> #{e}"

            connect!
          
            # If we can't connect to the server at all, we just put a line in the log file.
            # This can be parsed later to write back to the queue if desired
            if (tries += 1) > MAX_TRIES
              unless @current_message.blank?
                Kt::Queue::Queue.log("+++ #{Time.now.to_i} #{@current_message.inspect}", true)
                if Kt::Queue::Queue.failure_notification_observer
                  Kt::Queue::Queue.failure_notification_observer.call(@current_message, e)
                end
              end
            
              return nil 
            end

            retry  
          end

          return result
        end
    end
  end
end
