# Kontagent facebooker version 0.2.0
require 'kt/kt_analytics'

module Facebooker
  module Rails
    module Controller
      
      def application_is_not_installed_by_facebook_user_with_kontagent
        if request.request_uri == Kt::KtAnalytics.instance.m_call_back_req_uri || 
            (request.request_uri == Kt::KtAnalytics.instance.m_call_back_req_uri + "/")
          redirect_to session[:facebook_session].install_url
        else
          local_req_uri = Kt::KtAnalytics.instance.m_call_back_req_uri
          matches = request.request_uri.match(/#{local_req_uri}\/(.*)/)
          redirect_to session[:facebook_session].install_url(:next =>"#{matches[1]}")
        end
      end #application_is_not_installed_by_facebook_user_with_kontagent
      
      alias_method_chain :application_is_not_installed_by_facebook_user, :kontagent
    end #module Controller
    
  end
end


