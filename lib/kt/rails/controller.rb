# Kontagent facebooker version 0.2.0
require 'kt/kt_analytics'
require 'facebooker'
require 'ruby-debug'

module Kt
  module Rails
    module Controller

      def self.included(controller)
        controller.extend(ClassMethods)
        controller.before_filter(:store_user_id)
        controller.before_filter(:capture_user_data)
        controller.before_filter(:handle_kontagent, :except=>[:post_remove, :handle_iframe])      
        controller.before_filter(:verify_uninstall_signature,  :only=>[:post_remove])
      end
      
      def set_ab_testing_page(campaign)
        page_info = Kt::KtAnalytics.instance.m_ab_testing_mgr.get_ab_testing_page(campaign)
        msg_info = Kt::KtAnalytics.instance.m_ab_testing_mgr.get_ab_testing_message(campaign)
        Kt::KtAnalytics.instance.m_ab_testing_mgr.cache_ab_testing_msg_and_page(campaign, msg_info, page_info)
      end
      
      # DEPRECATED : we don't use iframes to track page views anymore.
      def handle_iframe
        page_uri = params[:page_uri]
        uid = params[:request_id]
      end      
      
      def post_remove
        puts "calling post_remove..."
        Kt::KtAnalytics.instance.save_app_removed(params[:fb_sig_user])
        render :nothing
      end  
      
      protected
      def verify_uninstall_signature
        puts "calling verify_uninstall_signature..." #xxx
        signature = ''
        keys = params.keys.sort
        keys.each do |key|
          next if key == 'fb_sig'
          next unless key.include?('fb_sig')
          key_name = key.gsub('fb_sig_', '')
          signature += key_name
          signature += '='
          signature += params[key]
        end
        signature += Facebooker.secret_key
        calculated_sig = Digest::MD5.hexdigest(signature)
        
        if calculated_sig != params[:fb_sig]
          #logger.warn "\n\nUNINSTALL :: WARNING :: expected signatures did not match\n\n" 
          return false
        else
          #logger.warn "\n\nUNINSTALL :: SUCCESS!! Signatures matched.\n" 
          post_remove  # force calling post_remove
          return true
        end
      end

      def store_user_id
        $CURR_API_KEY = request.parameters[:fb_sig_api_key] if $CURR_API_KEY.nil?
        return true
      end

      def capture_user_data
        begin
          unless true or App.current.theme.template.code == "snowball"
            user = session[:facebook_session].user
            key = "KT_" + Facebooker.api_key + "_" + user.id.to_s
            if cookies[key].blank?
              Kt::KtAnalytics.instance.send_user_data(user)
            end
            cookies[key] = {:value => 1.to_s , :expires => 2.weeks.from_now} # 2 weeks
          end
        rescue 
          # invalid session key.
        end
        
        return true
      end

      def handle_kontagent
        get_params = params
        
        # trace uninstall
        if params.has_key? :fb_sig_uninstall
          Kt::KtAnalytics.instance.save_app_removed(params)
          return true
        end

        # track install 
        if params.has_key? :installed and params[:installed] == "1"
          Kt::KtAnalytics.instance.save_app_added(params)
        end
        
        
        short_tag=nil
        if params.has_key? :kt_type
          # handle kontagent related parameters
          case params[:kt_type]
          when "ins" # invite sent
            Kt::KtAnalytics.instance.save_invite_send(params)
          when "in"  # invite click
            Kt::KtAnalytics.instance.save_invite_click(params)
          when "nt" # notification click
            Kt::KtAnalytics.instance.save_notification_click(params)
          when "nte" # email notification
            Kt::KtAnalytics.instance.save_notification_email_click(params)
          when "fdp"
            short_tag = Kt::KtAnalytics.instance.save_undirected_comm_click(params)
          else
            
          end

          # forward to the url without the kt_* params
          f_url =  get_stripped_kt_args_url(short_tag)
          #puts "f_url \n\t #{f_url}" #xxx
          redirect_to f_url
          
        else
          return true
        end
        
      end # handle_kontagent

      
      private
      def get_stripped_kt_args_url (short_tag = nil)
        get_params = request.parameters
        r_param_hash = {}

        get_params.each_pair do | get_key, get_val |
          if Kt::KtAnalytics.kt_args?(get_key.intern)
            if get_key == 'kt_d'
              r_param_hash['d'] = get_val
            elsif get_key == 'kt_ut'
              r_param_hash['ut'] = get_val
            end
            params.delete(get_key)
          elsif !get_key.include? "fb_sig"
            r_param_hash[get_key] = get_val
          end
        end
        
        if short_tag != nil
          r_param_hash['sut'] = short_tag
        end
        
        return build_url(r_param_hash)
        
      end #get_stripped_kt_args_url
      
      def build_url(param_hash)
	local_req_uri = Kt::KtAnalytics.instance.m_call_back_req_uri
	matches = request.path.match(/#{local_req_uri}(.*)/)

	if matches == nil
	  puts "found NO match!!!"
	  r_url = ""
	else
	  puts "found a match!!!"
	  puts "\t #{matches[1]}"
	  r_url = matches[1]
	  if r_url == "/"
	    r_url = ""
	  end
	end
	
        
#       puts "local_req_uri \n\t#{Kt::KtAnalytics.instance.m_call_back_req_uri}"
# 	puts "canvas_name  \n\t #{Kt::KtAnalytics.instance.m_canvas_name}"
# 	puts "request.request_uri  \n\t #{request.request_uri}"
# 	puts "param_hash \n\t #{param_hash.to_query}"
# 	puts "return_url \n\t#{Kt::KtAnalytics.instance.append_kt_query_str(r_url, param_hash.to_query)}"
        
	      r_url = Kt::KtAnalytics.instance.append_kt_query_str("/"+Kt::KtAnalytics.instance.m_canvas_name+r_url, 
							     param_hash.to_query)
        #puts "final_url \n\t#{r_url}"
	
        return r_url
      end
	
      module ClassMethods
	  
      end


    end
  end
end
