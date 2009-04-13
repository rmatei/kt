# Kontagent facebooker version 0.1.6

puts "loading kt..."

require 'facebook/session'


require 'kt/rails/helpers'

require 'facebooker/rails/publisher'
require 'facebook/rails/publisher'
#require 'facebooker/rails/controller'
require 'facebook/rails/controller'
require 'kt/rails/controller'

config = YAML::load_file("#{RAILS_ROOT}/config/kontagent.yml")

if config['mode'] == 'async'
  require 'starling'
  require 'starling_ext'

  require 'kt/queue/queue'
  require 'kt/queue/processor'
  require 'kt/queue/task'  

  # Load app applicable Kontagent::Queue::Processor subclasses from app/processors
  Dir[RAILS_ROOT + '/app/processors/*.rb'].each do |file|
    require file
  end
end

module ::ActionController
  class Base
    def self.inherited_with_kt(subclass)
      inherited_without_kt(subclass)
      
      if subclass.to_s == "ApplicationController"
        subclass.class_eval do
          subclass.send(:include,Kt::Rails::Controller)
        end
      end
      
    end #def
    
    class << self
      alias_method_chain :inherited, :kt
    end
    
  end
end


ActionView::Base.send :include, Kt::Rails::KontagentHelpers




