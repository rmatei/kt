# Kontagent facebooker version KONTAGENT_VERSION_NUMBER
require 'kt/kt_analytics'
require 'json'

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
      
      def gen_feedstory_link(link, uuid, st1=nil, st2=nil, st3=nil)
        Kt::KtAnalytics.instance.gen_feedstory_link(link , uuid, st1, st2, st3)
      end

      def kt_feedstory_send(uuid, st1=nil, st2=nil, st3=nil)
        uid = Kt::KtAnalytics.instance.get_fb_param(params, 'user')
        Kt::KtAnalytics.instance.kt_feedstory_send(uid, uuid, st1, st2, st3)
      end

      def gen_multifeedstory_link(link, uuid, st1=nil, st2=nil, st3=nil)
        Kt::KtAnalytics.instance.gen_multifeedstory_link(link, uuid, st1, st2, st3)
      end

      def kt_multifeedstory_send(uuid, st1=nil, st2=nil, st3=nil)
        uid = Kt::KtAnalytics.instance.get_fb_param(params, 'user')
        Kt::KtAnalytics.instance.kt_multifeedstory_send(uid, uuid, st1, st2, st3)
      end
      
      def kt_increment_goal_count(goal_id, inc)
        uid = Kt::KtAnalytics.instance.get_fb_param(params, 'user')
        Kt::KtAnalytics.instance.increment_goal_count(uid, goal_id, inc)
      end
      
      def kt_increment_multiple_goal_counts(assoc_array)
        uid = Kt::KtAnalytics.instance.get_fb_param(params, 'user')
        Kt::KtAnalytics.instance.increment_multiple_goal_counts(uid, assoc_array)
      end
      
      def kt_increment_monetization(money_value)
        uid = Kt::KtAnalytics.instance.get_fb_param(params, 'user')
        Kt::KtAnalytics.instance.increment_monetization(uid, money_value)
      end

      def gen_feedstory_link_vo(link, uuid, ab_test_serialized_str)
        info = JSON.parse(ab_test_serialized_str)
        st1 = "aB_" + info['campaign'] + "___" + info['handle_index'].to_s
        st2 = Kt::KtAnalytics.instance.format_kt_st2(info['data'][0])
        st3 = Kt::KtAnalytics.instance.format_kt_st3(info['data'][0])
        return gen_feedstory_link(link , uuid , st1 , st2 , st3)
      end
      
      def kt_get_ab_feed_msg_text(ab_test_serialized_str)
        info = JSON.parse(ab_test_serialized_str)
        return info['data'][3]
      end

      def kt_feedstory_send_vo(uuid, ab_test_serialized_str)
        info = JSON.parse(ab_test_serialized_str)
        st1 = "aB_" + info['campaign'] + "___" + info['handle_index'].to_s
        st2 = Kt::KtAnalytics.instance.format_kt_st2(info['data'][0])
        st3 = Kt::KtAnalytics.instance.format_kt_st3(info['data'][0])
        kt_feedstory_send(uuid, st1, st2, st3)
      end

      def gen_multifeedstory_link_vo(link, uuid, ab_test_serialized_str)
        info = JSON.parse(ab_test_serialized_str)
        st1 = "aB_" + info['campaign'] + "___" + info['handle_index'].to_s
        st2 = Kt::KtAnalytics.instance.format_kt_st2(info['data'][0])
        st3 = Kt::KtAnalytics.instance.format_kt_st3(info['data'][0])
        return gen_multifeedstory_link(link, uuid, st1, st2, st3)
      end

      def kt_multifeedstory_send_vo(uuid, ab_test_serialized_str)
        info = JSON.parse(ab_test_serialized_str)
        st1 = "aB_" + info['campaign'] + "___" + info['handle_index'].to_s
        st2 = Kt::KtAnalytics.instance.format_kt_st2(info['data'][0])
        st3 = Kt::KtAnalytics.instance.format_kt_st3(info['data'][0])
        kt_multifeedstory_send(uuid, st1, st2, st3)
      end

      alias_method_chain :application_is_not_installed_by_facebook_user, :kontagent
    end #module Controller
    
  end
end


