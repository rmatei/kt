# Kontagent facebooker version KONTAGENT_VERSION_NUMBER
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
    
      def gen_uuid()
        Kt::KtAnalytics.instance.gen_long_uuid()
      end
      
      def gen_feedstory_link(link, uuid, st1=nil, st2=nil)
        Kt::KtAnalytics.instance.gen_feedstory_link(link , uuid, st1, st2)
      end

      def kt_feedstory_send(uuid, st1=nil, st2=nil)
        uid = Kt::KtAnalytics.instance.get_fb_param(params, 'user')
        Kt::KtAnalytics.instance.kt_feedstory_send(uid, uuid, st1, st2)
      end

      def gen_multifeedstory_link(link, uuid, st1=nil, st2=nil)
        Kt::KtAnalytics.instance.gen_multifeedstory_link(link, uuid, st1, st2)
      end

      def kt_multifeedstory_send(uuid, st1=nil, st2=nil)
        uid = Kt::KtAnalytics.instance.get_fb_param(params, 'user')
        Kt::KtAnalytics.instance.kt_multifeedstory_send(uid, uuid, st1, st2)
      end
      
      def kt_increment_goal_count(goal_id, inc)
        uid = Kt::KtAnalytics.instance.get_fb_param(params, 'user')
        Kt::KtAnalytics.instance.increment_goal_count(uid, goal_id, inc)
      end

      def kt_increment_multiple_goal_counts(assoc_array)
        uid = Kt::KtAnalytics.instance.get_fb_param(params, 'user')
        Kt::KtAnalytics.instance.increment_multiple_goal_counts(uid, assoc_array)
      end

      alias_method_chain :application_is_not_installed_by_facebook_user, :kontagent
    end #module Controller
    
  end
end


