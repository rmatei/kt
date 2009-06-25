# Kontagent facebooker version KONTAGENT_VERSION_NUMBER
require 'kt/kt_analytics'
require 'ruby-debug'

module Facebooker
  class Session
    def send_notification_with_kontagent(user_ids, fbml, email_fbml = nil, source_user = nil, template_id = nil, st1 = nil, st2 = nil, campaign = nil)
      
      if !campaign.nil?
        # ab testing
        msg_id, msg_txt = Kt::KtAnalytics.instance.m_ab_testing_mgr.get_selected_msg_info(campaign)
        page_id, page_txt =Kt::KtAnalytics.instance.m_ab_testing_mgr.get_selected_page_info(campaign)      
        uuid,fbml = Kt::KtAnalytics.instance.gen_kt_comm_link_vo(fbml, :nt, nil, campaign, msg_id, page_id, msg_txt) 
      else
        uuid,fbml = Kt::KtAnalytics.instance.gen_kt_comm_link(fbml, :nt, template_id, st1, st2) 
      end
      
      r = send_notification_without_kontagent(user_ids, fbml, email_fbml)
      
      if !r.blank?
        arg_hash = {
          'r' => user_ids.is_a?(Array) ? user_ids * "," : user_ids,
          'u' => uuid 
        }

        if source_user.nil?
          arg_hash['s'] = 0.to_s
        else
          arg_hash['s'] = source_user.id.to_s
        end
        
        arg_hash['t'] = template_id.to_s unless template_id.nil?
        
        if !campaign.nil?
          arg_hash['st1'] = Kt::KtAnalytics.instance.format_kt_st1(campaign)
          arg_hash['st2'] = Kt::KtAnalytics.instance.format_kt_st2(msg_id)
          arg_hash['st3'] = Kt::KtAnalytics.instance.format_kt_st3(page_id)
        else
          arg_hash['st1'] = st1
          arg_hash['st2'] = st2
        end
        
        Kt::KtAnalytics.instance.kt_outbound_msg('nts', arg_hash)
      end
    end
    
    def send_email_with_kontagent(user_ids, subject, text, fbml = nil, template_id = nil, st1 = nil, st2 = nil, campaign = nil)
      if !campaign.nil?
        # ab testing
        msg_id, msg_txt = Kt::KtAnalytics.instance.m_ab_testing_mgr.get_selected_msg_info(campaign)
        page_id, page_txt =Kt::KtAnalytics.instance.m_ab_testing_mgr.get_selected_page_info(campaign)      
        if fbml != nil
          uuid, fbml = Kt::KtAnalytics.instance.gen_kt_comm_link_vo(fbml, :nte, nil, campaign, msg_id, page_id, msg_txt)
        else
          uuid = Kt::KtAnalytics.instance.gen_long_uuid
        end
      else
        if fbml != nil
          uuid, fbml = Kt::KtAnalytics.instance.gen_kt_comm_link(fbml, :nte, template_id, st1, st2, st3) 
        else
          uuid = Kt::KtAnalytics.instance.gen_long_uuid
        end
      end
      
      r = send_email_without_kontagent(user_ids, subject, text, fbml)
      
      if !r.blank?
        arg_hash = { 
          's' => @user.id.to_s , 
          'r' => user_ids.is_a?(Array) ? user_ids * "," : user_ids,
          'u' => uuid
        }
      
        
        arg_hash['t'] = template_id.to_s unless template_id.nil?
        if !campaign.nil?
          arg_hash['st1'] = Kt::KtAnalytics.instance.format_kt_st1(campaign)
          arg_hash['st2'] = Kt::KtAnalytics.instance.format_kt_st2(msg_id)
          arg_hash['st3'] = Kt::KtAnalytics.instance.format_kt_st3(page_id)
        else
          arg_hash['st1'] = st1
          arg_hash['st2'] = st2
        end
        
        Kt::KtAnalytics.instance.kt_outbound_msg('nte', arg_hash)
      end

    end
    
    # if st2 is set to m{d} and st3 is set to p{d}, we'll assume that it's using ab_testing data.
    def publish_user_action_with_kontagent(bundle_id,data={},target_ids=nil,body_general=nil, st1 = nil, st2 = nil, campaign=nil)
      if !campaign.nil?
        msg_id, msg_txt = Kt::KtAnalytics.instance.m_ab_testing_mgr.get_selected_msg_info(campaign)
        page_id, page_txt =Kt::KtAnalytics.instance.m_ab_testing_mgr.get_selected_page_info(campaign)      
        st1 = campaign
        st2 = msg_id
        st3 = page_id
      end

      if(data != nil)
        data.each_pair do |key,value |
          if key == :image
            if !campaign.nil?
              uuid, fbml = Kt::KtAnalytics.instance.gen_kt_comm_link_vo(value[:href], :fdp,
                                                                        bundle_id, st1, st2, st3, campaign)
            else
              uuid, fbml = Kt::KtAnalytics.instance.gen_kt_comm_link(value[:href], :fdp,
                                                                     bundle_id, st1, st2)
            end
            value[:href] = fbml
            data[key] = value # do we even need this line?
          elsif key == :flash
            
          elsif key == :mp3
            #Kt::KtAnalytics.instance.kt_outbound_msg('fdp', arg_hash)
          elsif key == :video
          else
            if !campaign.nil?
              uuid, fbml = Kt::KtAnalytics.instance.gen_kt_comm_link_no_href_vo(value, :fdp, bundle_id, st1, st2, st3)
            else
              uuid, fbml = Kt::KtAnalytics.instance.gen_kt_comm_link_no_href(value, :fdp, bundle_id, st1, st2)
            end
            data[key] =  fbml
          end
        end
      end
      
      data['KT_AB_MSG'] = msg_txt if !campaign.nil?
      
      r = publish_user_action_without_kontagent(bundle_id, data, target_ids, body_general)
      
      if !r.blank?
        arg_hash = {
          'pt' => 4,
          's' => @user.id.to_s,
          't' => bundle_id
        }
        
        Kt::KtAnalytics.instance.kt_outbound_msg('fdp', arg_hash) 
      end
    
    end
    
    alias_method_chain :send_notification, :kontagent
    alias_method_chain :send_email, :kontagent
    alias_method_chain :publish_user_action, :kontagent

  end
end
