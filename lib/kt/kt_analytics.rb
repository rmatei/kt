# Kontagent facebooker version 0.2.0

require 'kt/kt_comm_layer'
require 'kt/kt_ab_testing'
require 'kt/queue/task'
require 'digest/md5'
require 'ruby-debug'

module Kt
  class KtAnalytics
    @@URL_REGEX_STR = /(href\s*=.*?)(https?:\/\/[^\s>\'"]+)/ #matches all the urls
    @@URL_WITH_NO_HREF_REGEX_STR = /(https?:\/\/[^\s>\'"]+)/ #matches all the urls 
    @@KT_AB_MSG = /\{\*KT_AB_MSG\*\}/
    @@S_undirected_types = {:pr=>:pr, :fdp=>:fdp, :ad=>:ad, :ap=>:ap}
    @@S_directed_types = {:in=>:in, :nt=>:nt, :nte=>:nte}
    @@S_kt_args = {:kt_uid=>1, :kt_d=>1, :kt_type=>1, :kt_ut=>1, :kt_t=>1, :kt_st1=>1, :kt_st2=>1}
    @@S_install_args = {:d=>1, :ut=>1, :installed=>1,  :sut=>1}
    
    @@S_directed_val = 'd';
    @@S_undirected_val = 'u';
    @@instance_obj = nil
    
    attr_reader :m_comm, :m_kt_api_key, :m_canvas_name, :m_call_back_req_uri, :m_call_back_host, :m_kt_host, :m_kt_host_port, :m_kt_host_url, :m_ab_testing_mgr
    
    def self.instance()
      if @@instance_obj == nil
        @@instance_obj = new
        @@instance_obj.init
      end
      return @@instance_obj
    end

    def self.kt_args?(arg)
      if @@S_kt_args.has_key? arg
        return true
      else
        return false
      end
    end

    def self.install_args?(arg)
      if @@S_install_args.has_key? arg
        return true
      else
        return false
      end
    end

    def get_fb_param(request_params, param_name)
      r = 0
      if request_params.has_key?('fb_sig_' + param_name)
        r = request_params['fb_sig_'+param_name]
      elsif request_params.has_key?(Facebooker.api_key+"_"+param_name)
        r = request_params[Facebooker.api_key+"_"+param_name]
      end
      return r
    end
    
    private 
    def initialize()
      
    end
    
    def init_from_conf(custom_conf = nil)
      @config = YAML::load_file("#{RAILS_ROOT}/config/kontagent.yml")
      @config.merge! custom_conf if custom_conf
      
      #figure out the port
      if @config.has_key? $CURR_API_KEY
        app_config_map = @config[$CURR_API_KEY]
      else
        app_config_map = @config
      end
      
      if app_config_map['use_test_server'] == true
        if @config['kt_host_test_port'].blank? or @config['kt_host_test_port'].nil?
          @m_kt_host_port = 80
        else
          @m_kt_host_port = @config['kt_host_port']	
        end
      else
        if @config['kt_host_port'].blank? or @config['kt_host_port'].nil?
          @m_kt_host_port = 80
        else
          @m_kt_host_port = @config['kt_host_port']	
        end
      end

      # figure out the host
      if app_config_map['use_test_server'] == true
	@m_kt_host = @config['kt_host_test']
      else
	@m_kt_host = @config['kt_host']
      end

      if @m_kt_host_port != 80      
	@m_kt_host_url = "#{@m_kt_host}:#{@m_kt_host_port}"
      else
	@m_kt_host_url = "#{@m_kt_host}"	
      end
      
      @m_kt_url = @config['kt_url']
      
      @m_kt_api_key = app_config_map['kt_api_key'].to_s
      @m_kt_secret_key = app_config_map['kt_secret_key'].to_s
      @m_canvas_name = app_config_map['canvas_page_name']

      @m_call_back_req_uri = app_config_map['call_back_req_uri']
      @m_call_back_host = app_config_map['call_back_host']
      @m_mode = (@config['mode'] == 'async') ? :async : :sync
      @m_timeout = @config['timeout'].blank? ? 1 : @config['timeout'].to_i
      
      ##### possibly overriding ab_testing_host/port with some testing host port #####
      if app_config_map.has_key? 'ab_testing_host'
        @m_ab_testing_host = app_config_map['ab_testing_host']
      elsif @config.has_key? 'ab_testing_host'
        @m_ab_testing_host = @config['ab_testing_host']
      end
      
      if app_config_map.has_key? 'ab_testing_port'
        @m_ab_testing_port = app_config_map['ab_testing_port']
      elsif @config.has_key? 'ab_testing_port'
        @m_ab_testing_port = @config['ab_testing_port']
      end

      ##### the normal ab_testing_host/port #####
      if @m_ab_testing_host.nil? and @m_ab_testing_port.nil?
        if app_config_map.has_key? 'use_ab' or @config.has_key? 'use_ab'
          @m_ab_testing_host = 'http://www.kontagent.com'
          @m_ab_testing_port = 80
        end
      end
    end

    public
    def format_kt_st1(st1_str)
      return "aB_"+st1_str
    end

    def format_kt_st2(st2_str)
      return "m"+st2_str.to_s
    end

    def format_kt_st3(st3_str)
      return "p"+st3_str.to_s
    end
    
    def init(custom_conf = nil)
      init_from_conf(custom_conf) # to allow use of dynamic configs that aren't in the YML
      @m_comm = Kt::KtComm.instance(@m_kt_host, @m_kt_host_port)
      @m_ab_testing_mgr = Kt::AB_Testing_Manager.new(@m_kt_api_key, @m_kt_secret_key,
                                                     @m_ab_testing_host, 
                                                     @m_ab_testing_port) #TODO: get rid of the hardcoding stuff
    end

    def append_kt_query_str(original_url, query_str)
      if original_url =~ /\?/
        return original_url + "&" + query_str
      else
        if query_str == nil || query_str == ""
          return original_url
        else
          return original_url + "?" + query_str
        end
      end
    end

    def get_page_tracking_url(fb_user_id)
      arg_hash = {}
      arg_hash['s'] = fb_user_id
      @m_comm.get_call_url(@m_kt_url, "v1",
			   @m_kt_api_key, @m_kt_secret_key,
			   "pgr",
			   arg_hash)
    end

    def get_invite_post_link_and_uuid(post_link,  uid, template_id)
      uuid = gen_long_uuid
      url = get_invite_post_link(post_link, uid, uuid, template_id)
      return url , uuid
    end
    
    def get_invite_post_link(post_link, uid, uuid, template_id)
      arg_hash = {}
      arg_hash['kt_ut'] = uuid
      
      arg_hash['kt_uid'] = uid
      arg_hash['kt_type'] = 'ins'

      if template_id != nil
	arg_hash['kt_t'] = template_id
      end
      
      r_url = append_kt_query_str(post_link, arg_hash.to_query)

      return r_url
    end

    def get_invite_post_link_and_uuid_vo(post_link, uid, campaign)
      uuid = gen_long_uuid
      url = get_invite_post_link_vo(post_link, uid, uuid, campaign)
      return url , uuid
    end

    def get_invite_post_link_vo(post_link, uid, uuid, campaign)
      arg_hash = {}
      arg_hash['kt_uid'] = uid
      arg_hash['kt_ut'] = uuid
      arg_hash['kt_type'] = 'ins'
      arg_hash['kt_d'] = @@S_directed_val
      
      arg_hash['kt_st1'] = format_kt_st1(campaign)
      msg_id, msg_text = Kt::KtAnalytics.instance.m_ab_testing_mgr.get_selected_msg_info(campaign)
      arg_hash['kt_st2'] = format_kt_st2(msg_id)
      page_id, page_text = Kt::KtAnalytics.instance.m_ab_testing_mgr.get_selected_page_info(campaign)
      arg_hash['kt_st3'] = format_kt_st3(page_id)
      
      r_url = append_kt_query_str(post_link, arg_hash.to_query)
      return r_url
    end

    def get_invite_content_link(content_link, uid, uuid, template_id, subtype1, subtype2)
      arg_hash = {}
      arg_hash['kt_uid'] = uid
      arg_hash['kt_ut'] = uuid
      arg_hash['kt_type'] = 'in'
      arg_hash['kt_d'] = @@S_directed_val
      
      if template_id != nil
        arg_hash['kt_t'] = template_id
      end
      if subtype1 != nil
        arg_hash['kt_st1'] = subtype1
      end
      if subtype2 != nil
        arg_hash['kt_st2'] = subtype2
      end

      r_url = append_kt_query_str(content_link, arg_hash.to_query)
      return r_url
    end

    
    def get_invite_content_link_and_uuid(content_link, uid, template_id, subtype1, subtype2)
      uuid = gen_long_uuid
      url = get_invite_content_link(content_link, uid, uuid, template_id, subtype1, subtype2)
      return url, uuid
    end

    def get_invite_content_link_and_uuid_vo(content_link, uid, campaign)
      uuid = gen_long_uuid
      url = get_invite_post_link_vo(content_link, uid, uuid, campaign)
      return url, uuid
    end

    def get_invite_content_link_vo(content_link, uid, uuid, campaign)
      arg_hash = {}
      arg_hash['kt_uid'] = uid
      arg_hash['kt_ut'] = uuid
      arg_hash['kt_type'] = 'in'
      arg_hash['kt_d'] = @@S_directed_val

      arg_hash['kt_st1'] = format_kt_st1(campaign) 
      msg_id, msg_text = Kt::KtAnalytics.instance.m_ab_testing_mgr.get_selected_msg_info(campaign)
      arg_hash['kt_st2'] = format_kt_st2(msg_id)
      page_id, page_text = Kt::KtAnalytics.instance.m_ab_testing_mgr.get_selected_page_info(campaign)
      arg_hash['kt_st3'] = format_kt_st3(page_id)
      
      r_url = append_kt_query_str(content_link, arg_hash.to_query)
      return r_url
    end
    
    def gen_kt_comm_link(input_txt, comm_type, template_id, subtype1, subtype2)
      uuid,query_str = gen_kt_comm_query_str(comm_type, template_id, subtype1, subtype2, nil)
      input_txt = input_txt.gsub(@@URL_REGEX_STR){|match|
        if $1.nil?
          append_kt_query_str($2, query_str)
        else
          $1 + append_kt_query_str($2, query_str)
        end
      }
      
      return uuid,input_txt
    end #gen_kt_comm_link


    def gen_kt_comm_link_vo(input_txt, comm_type, template_id, campaign, msg_id, page_id, msg_txt)
      uuid, query_str = gen_kt_comm_query_str(comm_type, template_id, 
                                              format_kt_st1(campaign), 
                                              format_kt_st2(msg_id), 
                                              format_kt_st3(page_id))
      input_txt = input_txt.gsub(@@URL_WITH_NO_HREF_REGEX_STR){|match|
        if $1.nil?
          input_txt
        else
          append_kt_query_str($1, query_str)
        end
      }
      input_txt = input_txt.gsub(@@KT_AB_MSG){|match|
        msg_txt
      }
      return uuid, input_txt
    end

    def gen_kt_comm_link_no_href(input_txt, comm_type, template_id, subtype1, subtype2)
      uuid,query_str = gen_kt_comm_query_str(comm_type, template_id, subtype1, subtype2, nil)
      input_txt = input_txt.gsub(@@URL_WITH_NO_HREF_REGEX_STR){|match|
        if $1.nil?
          input_txt
        else
          append_kt_query_str($1, query_str)
        end
      }
      return uuid, input_txt
    end #gen_kt_comm_link_no_href    

    def gen_kt_comm_link_no_href_vo(input_txt, comm_type, template_id, campaign, msg_id, page_id)
      uuid,query_str = gen_kt_comm_query_str(comm_type, template_id, 
                                             format_kt_st1(campaign), 
                                             format_kt_st2(msg_id), 
                                             format_kt_st3(page_id))
      input_txt = input_txt.gsub(@@URL_WITH_NO_HREF_REGEX_STR){|match|
        if $1.nil?
          input_txt
        else
          append_kt_query_str($1, query_str)
        end
      }
      return uuid, input_txt
    end 

    def send_user_data_impl(user)
      arg_hash = {}
      
      if !user.birthday.blank? && user.birthday != ''
        arg_hash['b'] = user.birthday.split(" ")[-1]
      end
      if !user.sex.blank? && user.sex != ''
        arg_hash['g'] = user.sex[0,1]
      end
      
      # debugging
      RAILS_DEFAULT_LOGGER.warn "kt demographics - birthday: #{arg_hash['b'].inspect}"
      RAILS_DEFAULT_LOGGER.warn "kt demographics - gender: #{arg_hash['g'].inspect}"
      
      
#       if !user.current_location.city.blank? &&user.current_location.city != ''
#         arg_hash['ly'] = user.current_location.city
#       end
#       if !user.current_location.state.blank? && user.current_location.state != ''
#         arg_hash['ls'] = user.current_location.state
#       end
#       if !user.current_location.country.blank? && user.current_location.country != ''
#         arg_hash['lc'] = user.current_location.country
#       end
#       if !user.current_location.zip.blank? && user.current_location.zip != ''
#         arg_hash['lp'] = user.current_location.zip
#       end
      

#       if !user.hometown_location.city.blank? &&user.hometown_location.city != ''
#         arg_hash['ly'] = user.hometown_location.city
#       end
#       if !user.hometown_location.state.blank? && user.hometown_location.state != ''
#         arg_hash['ls'] = user.hometown_location.state
#       end
#       if !user.hometown_location.country.blank? && user.hometown_location.country != ''
#         arg_hash['lc'] = user.hometown_location.country
#       end
#       if !user.hometown_location.zip.blank? && user.hometown_location.zip != ''
#         arg_hash['lp'] = user.hometown_location.zip
#       end
      
      arg_hash['f'] = user.friends.size.to_s
      
      kt_outbound_msg('cpu', arg_hash)
      return true
    end
      
    def send_user_data(user)
      #sex', 'birthday', 'current_location', 'hometown_location
      if @m_mode == :async
        data_hash ={
          :qtype => :capture_user_data,
          :user => Marshal.dump(user)
        }
        Kt::Queue::Task.publish :record, data_hash        
      else
        send_user_data_impl(user)
      end
        
    end

    def save_app_removed(uid)
      arg_hash = {'s'=>uid}
      kt_outbound_msg('apr', arg_hash)
    end
    
    
    def save_app_added(request_params)
      has_direction = false
      if request_params[:d] != nil
        has_direction = true
      end
      
      arg_hash = {}
      
      arg_hash['s'] = get_fb_param(request_params, 'user')
      
      if has_direction == true and request_params[:d] == @@S_directed_val
        arg_hash['u'] = request_params[:ut]
        kt_outbound_msg('apa', arg_hash)
      elsif has_direction == true and request_params[:d] == @@S_undirected_val
        arg_hash['su'] = request_params[:sut]
        kt_outbound_msg('apa', arg_hash)
      else # no viral
        kt_outbound_msg('apa', arg_hash)
      end
    end
    
    def save_invite_send(request_params)
      arg_hash = {}
      arg_hash['s'] = request_params[:kt_uid]
      arg_hash['r'] = request_params[:ids].is_a?(Array) ? request_params[:ids] * "," : request_params[:ids]
      arg_hash['u'] = request_params[:kt_ut]
      
      arg_hash['t']   = request_params[:kt_t]   if !request_params['kt_t'].nil?
      arg_hash['st1'] = request_params[:kt_st1] if !request_params['kt_st1'].nil?
      arg_hash['st2'] = request_params[:kt_st2] if !request_params['kt_st2'].nil?
      arg_hash['st3'] = request_params[:kt_st3] if !request_params['kt_st3'].nil?
      
      kt_outbound_msg('ins', arg_hash)
    end

    def save_invite_click(request_params)
      arg_hash = {}
      arg_hash['i'] = get_fb_param(request_params, 'added')
      arg_hash['u'] = request_params[:kt_ut]
      arg_hash['tu'] = 'inr'
      
      arg_hash['t']   = request_params[:kt_t]   if !request_params['kt_t'].nil?
      arg_hash['st1'] = request_params[:kt_st1] if !request_params['kt_st1'].nil?
      arg_hash['st2'] = request_params[:kt_st2] if !request_params['kt_st2'].nil?
      arg_hash['st3'] = request_params[:kt_st3] if !request_params['kt_st3'].nil?
      
      kt_outbound_msg('inr', arg_hash)
    end


    def save_notification_click(request_params)
      msg_type = 'ntr'
      arg_hash = construct_arg_hash_for_click_event_helper(msg_type, request_params)
      kt_outbound_msg(msg_type, arg_hash)
    end
    
    def save_notification_email_click(request_params)
      msg_type = 'nei'
      arg_hash = construct_arg_hash_for_click_event_helper(msg_type, request_params)
      kt_outbound_msg(msg_type, arg_hash)
    end
    
    def save_undirected_comm_click(request_params)
      msg_type = 'ucc'
      arg_hash = {}
      arg_hash['t'] = request_params[:kt_t] unless request_params[:kt_t] == nil
      arg_hash['st1'] = request_params[:kt_st1] unless request_params[:kt_st1] == nil
      arg_hash['st2'] = request_params[:kt_st2] unless request_params[:kt_st2] == nil
      arg_hash['st3'] = request_params[:kt_st3] unless request_params[:kt_st3] == nil
      arg_hash['tu'] = request_params[:kt_type] 
      arg_hash['s'] = get_fb_param(request_params, 'user')
      short_tag = gen_short_uuid
      arg_hash['su'] = short_tag
      arg_hash['i'] = get_fb_param(request_params, 'added')
      kt_outbound_msg(msg_type, arg_hash)
      return short_tag
    end

    def kt_outbound_msg(type, arg_hash)
      if @m_mode == :async      
        #timeout(@m_timeout) do
        data_hash = {
          :qtype => :kt_outbound,
          :ctype => type,
          :v => 'v1',
          :kt_api_key => @m_kt_api_key,
          :kt_secret_key => @m_kt_secret_key,
          :kt_call_back_host => @m_kt_host,
          :kt_call_back_port => @m_kt_host_port,
          :kt_url => @m_kt_url,
          :arg_hash => arg_hash,
        }
        Kt::Queue::Task.publish :record, data_hash
        #end
      else
        @m_comm.api_call_method(@m_kt_url, 'v1', @m_kt_api_key, @m_kt_secret_key, type, arg_hash)
      end
    end
    
    begin
      require "#{RAILS_ROOT}/vendor/plugins/rpm/init"
      add_method_tracer :kt_outbound_msg, 'Custom/Kontagent/kt_outbound_msg'
    rescue
      puts "Failed to add New Relic instrumentation to Kontagent."
    end
    
    # It's more secure to have 32 characters
    def gen_long_uuid()
      CGI::Session.generate_unique_id('kontagent')
    rescue
      # Rails 2.3 fix
      ActiveSupport::SecureRandom.hex(16)
    end
    
    private
    def construct_arg_hash_for_click_event_helper(msg_type, request_params)
      arg_hash = {}
      arg_hash['tu'] = msg_type
      arg_hash['i'] = get_fb_param(request_params, 'added')
      if request_params.has_key? 'kt_ut'
        arg_hash['u'] = request_params[:kt_ut]
      end
      
      arg_hash['t'] = request_params[:kt_t] if request_params.has_key? 'kt_t'
      arg_hash['st1'] = request_params[:kt_st1] if request_params.has_key? 'kt_st1'
      arg_hash['st2'] = request_params[:kt_st2] if request_params.has_key? 'kt_st2'
      arg_hash['st3'] = request_params[:kt_st3] if request_params.has_key? 'kt_st3'

      uid = get_fb_param(request_params, 'user')
      if uid != 0
        arg_hash['r'] = uid
      end
      return arg_hash
    end

    def gen_short_uuid()
      gen_long_uuid[0...8]
    end

    def directed_type?(comm_type)
      @@S_directed_types.has_key?(comm_type)
    end

    def undirected_type?(comm_type)
      @@S_undirected_types.has_key?(comm_type)
    end
    
    
    def gen_kt_comm_query_str(comm_type, template_id, subtype1, subtype2, subtype3)
      param_array = {}
      uuid = 0
      
      if comm_type != nil
        if directed_type? comm_type
          dir_val = @@S_directed_val
        elsif undirected_type? comm_type
          dir_val = @@S_undirected_val
        else
          # profile?
        end
      end
      
      param_array[:kt_d] = dir_val
      param_array[:kt_type] = comm_type
      
      if dir_val == @@S_directed_val
        uuid = gen_long_uuid()
        param_array[:kt_ut] = uuid
      end
      
      param_array[:kt_t] = template_id.to_s if !template_id.nil?
      param_array[:kt_st1] = subtype1 if !subtype1.nil?
      param_array[:kt_st2] = subtype2 if !subtype2.nil?
      param_array[:kt_st3] = subtype3 if !subtype3.nil?
      
      return uuid, param_array.to_query
    end #gen_kt_comm_query_str

  end #Kt_Analytics

end#mdoule
