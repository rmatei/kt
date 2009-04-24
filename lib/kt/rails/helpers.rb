# Kontagent facebooker version 0.1.6

require 'kt/kt_analytics'
require 'cgi'

module Kt
  module Rails
    module KontagentHelpers
      
      def kt_get_invite_post_link(invite_post_link, template_id=nil)
        url = nil
        uid = Kt::KtAnalytics.instance.get_fb_param(params, 'user')
        
        if session['invite_uuid']  == nil
          url, uuid = Kt::KtAnalytics.instance.get_invite_post_link_and_uuid(invite_post_link, 
                                                                             uid,
                                                                             template_id)
          session['invite_uuid'] = uuid
        else
          url = Kt::KtAnalytics.instance.get_invite_post_link(invite_post_link, 
                                                              uid,
                                                              session['invite_uuid'], 
                                                              template_id)
          session['invite_uuid'] = nil
        end
        return url
      end
      
      def kt_get_invite_content_link(invite_content_link, template_id = nil, subtype1 = nil, subtype2 = nil)
        url = nil
        uid = Kt::KtAnalytics.instance.get_fb_param(params, 'user')
        
        if session['invite_uuid'] == nil
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
          session['invite_uuid'] = nil
        end
        return url
      end

      def kt_track_page_view()
	uid = Kt::KtAnalytics.instance.get_fb_param(params, 'user')
        url_str = Kt::KtAnalytics.instance.get_page_tracking_url(uid)
	track_code_str = "<img src='http://#{Kt::KtAnalytics.instance.m_kt_host_url}#{url_str}' width='0px' height='0px' />"
	return track_code_str
      end
      
    end
      
  end
end
