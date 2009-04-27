# Kontagent facebooker version 0.2.0

module Kt
  module Queue
    LOST_CONNECTION_ERROR_MESSAGES = [
      "Server shutdown in progress",
      "Broken pipe",
      "Lost connection to MySQL server during query",
      "MySQL server has gone away"
    ]
  
    # An object not found proxy exception. This is used inside our generated getter methods
    # to rescue ActiveRecord::RecordNotFound
    class NotFound < Exception; end
  
    class Processor
      def options
        @task.options
      end
      
      
      # Takes a class name and returns and creates an accessor method and instance
      # variable for it. If the class responds to find (i.e. ActiveRecord objects), then
      # it tries to call it with the value of name_id extracted from the Task.
      # If not, it creates a new instaces of the class, sets an instance variable with that name 
      # and returns it.
      def self.processes(name)
        name = name.to_s
        define_method(name) do
          ivar = instance_variable_get("@#{name}")
          return ivar unless ivar.blank?
        
          object = Object.const_get(name.camelize)
        
          value = if object.respond_to?(:find)
            begin
              object.find(@task.options["#{name}_id".intern])
            
            # We provide automatic ActiveRecord::RecordNotFound protection because this method
            # useless without a correct instance of the model.
            rescue ActiveRecord::RecordNotFound => rnf
              raise Kt::NotFound, rnf.message
            end
          else
            Object.const_get(name.camelize).send('new')
          end
          instance_variable_set("@#{name}", value)
        
          value
        end      
      end
    
      # Runs the process method defined in the Processor subclass (in app/processors).
      # Any error that is fatal should be rescued to avoid re-entry in to the queue. As a default, we rescue 
      # ActiveRecord::RecordNotFound (record not found).
      # Subclasses of Processor should rescue any fatal errors specific to them in their own process method.
      def process!(task)
        @task = task
      
        tries = 0

        begin
          process
        rescue ActiveRecord::StatementInvalid => sti
          lost_connection = false
          LOST_CONNECTION_ERROR_MESSAGES.each do |error|
            lost_connection = true if sti.message =~ /#{error}/
          end
          if lost_connection && tries == 0
            tries += 1
            ActiveRecord::Base.connection.reconnect!
          
            retry
          end
        
          task.enqueue_with_error(sti)
        rescue Kt::Queue::NotFound => notfound
        rescue Exception => e
          task.enqueue_with_error(e)
        end
      end
    end
  end
end
