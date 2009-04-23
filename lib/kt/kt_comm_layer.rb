# Kontagent facebooker version 0.1.6
#require 'socket'
require 'net/http'
#require 'timeout'
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

#       url_path = get_call_url(kt_api_url, version, api_key, secret_key, api_func, arg_assoc_hash)
#       url_path = "http://"+@m_host+":"+@m_port.to_s+url_path
#       uri = URI.parse(url_path)
#       Net::HTTP.get(uri)
      socket = Socket.new(AF_INET, SOCK_STREAM, 0)
      sockaddr = Socket.sockaddr_in(@m_port, @m_host)

      connected = true

      #puts Benchmark.measure{
      begin
        socket.connect_nonblock(sockaddr)
      rescue Errno::EINPROGRESS
        IO.select(nil, [socket])
        begin
          socket.connect_nonblock(sockaddr)
        rescue Errno::EISCONN
          connected = false
          # puts "Errno::EISCONN!!"
        end
      end
      #}
      
      if connected
        url_path = get_call_url(kt_api_url, version, api_key, secret_key, api_func, arg_assoc_hash)

        buf = "GET " + url_path + " HTTP/1.1\r\n"
        buf << "Host:" + @m_host + "\r\n"
        buf << "Content-type: application/x-www-form-urlencoded\r\n"
        buf << "Accept: */*\r\n"
        buf << "\r\n"
        buf << "\r\n"
      
        socket.write_nonblock buf
      end
      socket.close
      
      return connected
#     socket = nil
      
#         puts @m_host
#         begin
#           timeout(2) do
#             #socket = TCPSocket::new(@m_host, 80) #uncomment this
#             socket = TCPSocket::new(@m_host, @m_port)
#           end
#         rescue Timeout::Error
#           puts "timeout!!!"
#           return
#         rescue
#           puts "tcp error!!!!"
#           return
#         end

#         if socket != nil
#           url_path = get_call_url(kt_api_url, version, api_key, secret_key, api_func, arg_assoc_hash)
#   	#puts "url_path: #{url_path}" #xxx
      
#           buf = "GET " + url_path + " HTTP/1.1\r\n"
#           buf << "Host:" + @m_host + "\r\n"
#           buf << "Content-type: application/x-www-form-urlencoded\r\n"
#           buf << "Accept: */*\r\n"
#           buf << "\r\n"
#           buf << "\r\n"
#           socket.write buf
#           socket.close
#         end

        #         old code
        #         socket.write("GET " + url_path + " HTTP/1.1\r\n")
        #         socket.write("Host:" + @m_host + "\r\n")
        #         socket.write("Content-type: application/x-www-form-urlencoded\r\n")
        #         socket.write("Accept: */*\r\n")
        #         socket.write("\r\n")
        #         socket.write("\r\n")
        #         socket.close        
    #end
    end
    
    def get_call_url(kt_api_url, version, api_key, secret_key, api_func, arg_assoc_hash)
      sig = ''
      arg_assoc_hash['ts'] = Time.now.to_s
      
      # This is to get rid of null parameters. in the assoc array      
      
      keys = arg_assoc_hash.keys.sort
      keys.each do |key| 
        sig += key+"="+arg_assoc_hash[key].to_s
      end
      
      arg_assoc_hash['an_sig'] = Digest::MD5.hexdigest(sig)
      
      query = arg_assoc_hash.to_query
      url_path = kt_api_url+"/"+version+"/"+api_key+"/"+api_func+"/?"+query
    end
    
  end

end


# test 

#comm = Kontagent::Kt_Comm.new('67.102.65.65')
#comm = Kontagent::Kt_Comm.new('10.0.0.0')
#comm.api_call_method('/api', 'test', '123','345', 'api_func', {'a'=>'foo'})
