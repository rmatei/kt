# Kontagent facebooker version 0.2.0
# Install hook code here
require 'fileutils'
require 'rubygems'
#require 'ruby-debug' #xxx

if ARGV.size != 2
  puts "Failure: you need to pass in the controller_name"
else
  controller_name = ARGV[1]
  handle_iframe_html_dst = File.join(RAILS_ROOT, "app", "views", controller_name, "handle_iframe.html.erb")
  handle_iframe_fbml_dst = File.join(RAILS_ROOT, "app", "views", controller_name, "handle_iframe.fbml.erb")
  kontagent_yml_dst = File.join(RAILS_ROOT, "config", "kontagent.yml")
  
  puts "copying kontagent.yml.erb to #{kontagent_yml_dst}"
  FileUtils.cp( File.join(RAILS_ROOT, "vendor", "plugins", "kt", 'kontagent.yml.tpl'),
                kontagent_yml_dst ) unless File.exists?( kontagent_yml_dst )
end


