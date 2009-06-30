# Kontagent facebooker version KONTAGENT_VERSION_NUMBER
#require 'socket'
require 'net/http'
require 'timeout'
require 'cgi'
require 'uri'
require 'digest/md5'
#require 'benchmark'
include Socket::Constants


module Kt
  class KtComm
    @@instance_obj = nil
    private
    def initialize(host, port)
      puts "initializing KtComm"
      @m_host = host
      @m_port = port
      
      if @m_host == "api.geo.kontagent.net"
        @m_ip = fetch_ip()
      else
        @m_ip = host
      end
    end
    
    def _fetch_ip_helper(host_name_str, port)
      ip_lst = Socket.getaddrinfo(host_name_str, 'http')
      ip_lst.sort_by{ rand }
      selected_ip = nil

      ip_lst.each do |ip_info|
        ip_str = ip_info[3]
        socket = Socket.new(AF_INET, SOCK_STREAM, 0)
        sockaddr = Socket.sockaddr_in(port, ip_str)
        status = -1
        timeout(2) do
          status = socket.connect(sockaddr)
        end 
        if status == 0
          selected_ip = ip_str
          break
        end
      end #loop
      return selected_ip
    end # _fetch_ip_helper
      
    def fetch_ip()
      selected_ip = _fetch_ip_helper(@m_host, @m_port)

      if selected_ip.nil?
        selected_ip = _fetch_ip_helper("api.global.kontagent.net", 80) 
      end
      
      return selected_ip
    end
    
    public
    def self.instance(host, port)
      if @@instance_obj == nil
        @@instance_obj = new(host, port)
      end
      return @@instance_obj
    end


    # kt_api_url : excludes the host name.
    # version : example, v1, v2, etc.
    # api_key : kontagent's api key is used to uniquely identify the user.
    # secret_key : kontagent's secret key
    # api_func : example, ins for "invite sent", inr for "invite clicked", etc
    # arg_assoc_hash : an associative hash of argument list. 
    def api_call_method(kt_api_url, version, api_key, secret_key, api_func, arg_assoc_hash)

      socket = Socket.new(AF_INET, SOCK_STREAM, 0)
      sockaddr = Socket.sockaddr_in(@m_port, @m_ip)
        
      connected = true

      #puts Benchmark.measure{
      begin
        socket.connect_nonblock(sockaddr)
      rescue Errno::EINPROGRESS
        IO.select(nil, [socket])
        begin
          socket.connect_nonblock(sockaddr)
        rescue Errno::EISCONN
          #connected = false
          #puts "Errno::EISCONN!!"
        rescue
          connected = false
          puts "Errno during socket.connect_nonblock"
        end
      end
      #}
      
      if connected
        url_path = get_call_url(kt_api_url, version, api_key, secret_key, api_func, arg_assoc_hash)

        buf = "GET " + url_path + " HTTP/1.1\r\n"
        buf << "Host:" + @m_ip + ":" + @m_port.to_s + "\r\n"
        buf << "Content-type: application/x-www-form-urlencoded\r\n"
        buf << "Accept: */*\r\n"
        buf << "\r\n"
        buf << "\r\n"
      
        socket.write_nonblock buf
      end
      socket.close
      
      return connected
    end
    
    def get_call_url(kt_api_url, version, api_key, secret_key, api_func, arg_assoc_hash)
      sig = ''
      arg_assoc_hash['ts'] = Time.now.to_s
      
      # This is to get rid of null parameters. in the assoc array      
      
      keys = arg_assoc_hash.keys.sort
      keys.each do |key| 
        sig += key+"="+arg_assoc_hash[key].to_s
      end
      
      sig += secret_key

      arg_assoc_hash['an_sig'] = Digest::MD5.hexdigest(sig)

      query = arg_assoc_hash.to_query
      url_path = kt_api_url+"/"+version+"/"+api_key+"/"+api_func+"/?"+query
    end
    
  end

end


# test 
#comm = Kt::KtComm.new('kthq.dyndns.org', '8080')
#comm = Kontagent::Kt_Comm.new('10.0.0.0')
#comm.api_call_method('/api', 'test', '123','345', 'api_func', {'a'=>'foo'})
