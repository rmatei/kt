# Kontagent facebooker version KONTAGENT_VERSION_NUMBER

require 'kt/kt_analytics'
require 'cgi'
require 'ruby-debug'

module Kt
  module Rails
    module KontagentHelpers
      # example: page_custom_data : { 'foo' => 'FOO' }
      def kt_get_page_text(campaign, page_custom_data=nil)
        page_id, page_text = Kt::KtAnalytics.instance.m_ab_testing_mgr.get_selected_page_info(campaign, page_custom_data)
        return page_text
      end
      # example: msg_custom_data : { 'foo' => 'FOO' }
      def kt_get_msg_text(campaign, msg_custom_data=nil)
        msg_id, msg_text = Kt::KtAnalytics.instance.m_ab_testing_mgr.get_selected_msg_info(campaign, msg_custom_data)
        return msg_text
      end
      
      def kt_get_msg_buttons(campaign, index)
        msg_id, msg_buttons = Kt::KtAnalytics.instance.m_ab_testing_mgr.get_selected_msg_info_button(campaign)
        if msg_id.nil? 
          return ""
        end

        if msg_buttons[index].nil?
          return ""
        else
          msg_buttons[index]
        end
      end

      def kt_get_msg_title(campaign)
        msg_id, msg_title = Kt::KtAnalytics.instance.m_ab_testing_mgr.get_selected_msg_info_title(campaign)
        return msg_title
      end

      def kt_get_invite_post_link_vo(invite_post_link, campaign)
        url = nil
        uid = Kt::KtAnalytics.instance.get_fb_param(params, 'user')
        
        if session['invite_uuid'].nil?
          url, uuid = Kt::KtAnalytics.instance.get_invite_post_link_and_uuid_vo(invite_post_link,
                                                                                uid,
                                                                                campaign)
          session['invite_uuid'] = uuid
        else
          url = Kt::KtAnalytics.instance.get_invite_post_link_vo(invite_post_link,
                                                                 uid, 
                                                                 session['invite_uuid'],
                                                                 campaign)
#          session['invite_uuid'] = nil
        end
        return url
      end

      def kt_clear_invite_tag()
        session['invite_uuid'] = nil
      end

      def kt_get_invite_content_link_vo(invite_content_link, campaign)
        url = nil
        uid = Kt::KtAnalytics.instance.get_fb_param(params, 'user')
        
        if session['invite_uuid'].nil?
          url, uuid = Kt::KtAnalytics.instance.get_invite_content_link_and_uuid_vo(invite_content_link,
                                                                                   uid,
                                                                                   campaign)
          session['invite_uuid'] = uuid
        else
          url = Kt::KtAnalytics.instance.get_invite_content_link_vo(invite_content_link,
                                                                    uid,
                                                                    session['invite_uuid'],
                                                                    campaign)
          #session['invite_uuid'] = nil
        end
        return url
      end

      def kt_get_invite_post_link(invite_post_link, template_id=nil)
        url = nil
        uid = Kt::KtAnalytics.instance.get_fb_param(params, 'user')
        
        if session['invite_uuid'].nil?
          url, uuid = Kt::KtAnalytics.instance.get_invite_post_link_and_uuid(invite_post_link, 
                                                                             uid,
                                                                             template_id)
          session['invite_uuid'] = uuid
        else
          url = Kt::KtAnalytics.instance.get_invite_post_link(invite_post_link, 
                                                              uid,
                                                              session['invite_uuid'], 
                                                              template_id)
          #session['invite_uuid'] = nil
        end
        return url
      end
      
      def kt_get_invite_content_link(invite_content_link, template_id = nil, subtype1 = nil, subtype2 = nil)
        url = nil
        uid = Kt::KtAnalytics.instance.get_fb_param(params, 'user')
        
        if session['invite_uuid'].nil?
          url, uuid = Kt::KtAnalytics.instance.get_invite_content_link_and_uuid(invite_content_link,
                                                                                uid,
                                                                                template_id,
                                                                                subtype1,subtype2)
          session['invite_uuid'] = uuid
        else
          url = Kt::KtAnalytics.instance.get_invite_content_link(invite_content_link,
                                                                 uid,
                                                                 session['invite_uuid'],
                                                                 template_id,
                                                                 subtype1,subtype2)
          #session['invite_uuid'] = nil
        end
        return url
      end

      def kt_track_page_view()
        if Kt::KtAnalytics.instance.m_is_disabled
          return ""
        end

	uid = Kt::KtAnalytics.instance.get_fb_param(params, 'user')
        url_str = Kt::KtAnalytics.instance.get_page_tracking_url(uid)
	track_code_str = "<img src='http://#{Kt::KtAnalytics.instance.m_kt_host_url}#{url_str}' width='0px' height='0px' />"
	return track_code_str
      end
      
      def kt_get_callback_url()
        return Kt::KtAnalytics.instance.m_call_back_host + Kt::KtAnalytics.instance.m_call_back_req_uri
      end

      def kt_get_serialized_msg_page_tuple(campaign, pg_custom_data=nil, msg_custom_data=nil)
        info = Kt::KtAnalytics.instance.m_ab_testing_mgr.get_selected_page_msg_info(campaign,
                                                                                    pg_custom_data,
                                                                                    msg_custom_data)
        return Kt::KtAnalytics.instance.m_ab_testing_mgr.serialize_msg_page_tuple_helper(campaign, 
                                                                                         info)
      end

    end
      
  end
end
