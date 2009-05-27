require 'rubygems' #xxx
require 'memcache'
require 'net/http'
require 'uri'
require 'json'
require 'ruby-debug'

module Kt
  class AB_Testing_Manager

    @@URL_PREFIX = "/abtest/campaign_info";

    public
    def initialize(kt_api_key, kt_secret_key,
                   kt_ab_backend_host, kt_ab_backend_port)
      @m_backend_api_key = kt_api_key
      @m_backend_secret_key = kt_secret_key
      
      @m_ab_backend_host = kt_ab_backend_host
      @m_ab_backend_port = kt_ab_backend_port

      if @m_ab_backend_port != 80
        @m_ab_backend = @m_ab_backend_host + ":" + @m_ab_backend_port.to_s
      else
        @m_ab_backend = @m_ab_backend_host
      end
      
      @m_memcached_server = MemCache.new '127.0.0.1'
      @m_selected_msg_page_pair_dict = {}
    end

    private
    def fetch_ab_testing_data(campaign, force=false)
      begin
        url_str = @m_ab_backend + @@URL_PREFIX + "/" + @m_backend_api_key + "/" + campaign + "/"
        if force == true
          url_str += "?f=1"
        end

        url = URI.parse(url_str)
        if url.query.nil?
          url_str = url.path
        else
          url_str = url.path + "?" + url.query
        end
        req = Net::HTTP::Get.new(url_str)
        res = Net::HTTP.start(url.host, url.port) {|http|
          http.request(req)
        }
        json_obj = JSON.parse(res.body)

        if json_obj["changed"] == true
          msg_lst = json_obj["messages"]
          msg_weight_array = []
          curr_idx = 0
          
          # process message list
          msg_lst.each do |m|
            w = m[1]
            w.times { msg_weight_array << curr_idx }
            curr_idx += 1
          end
          
          # process page list
          page_lst = json_obj['pages']
          page_weight_array = []
          curr_idx = 0
          page_lst.each do |p|
            w = p[1]
            w.times { page_weight_array << curr_idx }
            curr_idx += 1
          end
          
          store_dict = {}
          store_dict['json'] = json_obj
          store_dict['msg_weight'] = msg_weight_array
          store_dict['page_weight'] = page_weight_array
          
          r = store_dict
          @m_memcached_server.set( gen_memcache_key(campaign), Marshal.dump(r), 0)
          @m_memcached_server.set( gen_memcache_fake_key(campaign), 1, 300 )
        else
          # no change
          @m_memcached_server.set( gen_memcache_fake_key(campaign), 1, 300 )
        end

      rescue Errno::ECONNREFUSED
        # TODO fall back on some default value
      end
        
        
      return r
    end
    
    private
    def get_ab_helper(campaign)
      fake_key_is_valid = @m_memcached_server.get( gen_memcache_fake_key(campaign) )
      if fake_key_is_valid.nil?
        # The real key should have a valid json object.
        # If not, invoke fetch_ab_testin_data with force = true
        serialized_campaign_str = @m_memcached_server.get( gen_memcache_key(campaign) )
        if serialized_campaign_str.nil?
          r = fetch_ab_testing_data(campaign, true) # force it
        else
          r = fetch_ab_testing_data(campaign)
        end
      else
        # Likewise, the real key should have a valid json object.
        # If not, invoke fetch_ab_testin_data with force = true
        serialized_campaign_str = @m_memcached_server.get( gen_memcache_key(campaign) )
        if serialized_campaign_str.nil?
          r = fetch_ab_testing_data(campaign, true) # force it
        else
          r = Marshal.load( serialized_campaign_str )
        end
      end
      return r
    end
    
    
    public
    def get_ab_testing_campaign_handle_index(campaign)
      dict = get_ab_helper(campaign)
      if dict.nil?
        return nil
      else
        json_obj = dict['json']        
        return json_obj['handle_index']
      end
    end

    public
    def get_ab_testing_message(campaign)
      dict = get_ab_helper(campaign)
      if dict.nil?
        return nil
      else
        json_obj = dict['json']
        msg_lst = json_obj['messages']
        weight_array = dict['msg_weight']
        index = weight_array[rand(weight_array.size)]
        return msg_lst[index]
      end
    end

    public
    def get_ab_testing_page(campaign)
      dict = get_ab_helper(campaign)
      if dict.nil?
        return nil
      else
        json_obj = dict['json']
        page_lst = json_obj['pages']
        weight_array = dict['page_weight']
        index = weight_array[rand(weight_array.size)]
        return page_lst[index]
      end
    end

    public
    def cache_ab_testing_msg_and_page(campaign, msg_info, page_info)
      @m_selected_msg_page_pair_dict[campaign] = {'page'=>page_info, 'msg'=>msg_info}
    end

    public 
    def get_selected_msg_info(campaign)
      msg_info = @m_selected_msg_page_pair_dict[campaign]['msg']
      if msg_info.nil?
        return nil
      else
        return msg_info[0], msg_info[2]
      end
    end

    def get_selected_msg_info_button(campaign)
      msg_info = @m_selected_msg_page_pair_dict[campaign]['msg']
      if msg_info.nil?
        return nil
      else
        return msg_info[0], msg_info[3]
      end
    end

    def get_selected_page_info(campaign)
      page_info = @m_selected_msg_page_pair_dict[campaign]['page']
      if page_info.nil?
        return nil
      else
        return page_info[0], page_info[2]
      end
    end

    private
    def gen_memcache_fake_key(campaign)
      return "kt_"+@m_backend_api_key+"_"+campaign+"_fake"
    end
    
    private
    def gen_memcache_key(campaign)
      return "kt_"+@m_backend_api_key+"_"+campaign
    end

  end

end  # module

# mgr = Kt::AB_Testing_Manager.new('ea04b006c8174440a264ab4ab5b1e4e0', '45237b3a91184c389a4c12f38e7fe755',
#                                  'http://kthq.dyndns.org', 9999)
# #mgr.fetch_ab_testing_data('hello')
# puts mgr.get_ab_testing_message('hello')
# puts mgr.get_ab_testing_page('hello')
