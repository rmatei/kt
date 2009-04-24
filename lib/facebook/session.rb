# Kontagent facebooker version 0.1.6
require 'kt/kt_analytics'

module Facebooker
  class Session
    def send_notification_with_kontagent(user_ids, fbml, email_fbml = nil, source_user = nil, template_id = nil, st1 = nil, st2 = nil)
      uuid,fbml = Kt::KtAnalytics.instance.gen_kt_comm_link(fbml, :nt, template_id, st1, st2) 
      r = send_notification_without_kontagent(user_ids, fbml, email_fbml)
      
      if !r.blank?
        arg_hash = {
          #'s' => @user.id.to_s,
          'r' => user_ids.is_a?(Array) ? user_ids * "," : user_ids,
          'u' => uuid 
        }

        if source_user.nil?
          arg_hash['s'] = 0.to_s
        else
          arg_hash['s'] = source_user.id.to_s
        end
        
        arg_hash['t'] = template_id.to_s unless template_id.nil?
        
        Kt::KtAnalytics.instance.kt_outbound_msg('nts', arg_hash)
      end
    end
    
    def send_email_with_kontagent(user_ids, subject, text, fbml = nil, template_id = nil, st1 = nil, st2 = nil)
      if fbml != nil
        uuid, fbml = Kt::KtAnalytics.instance.gen_kt_comm_link(fbml, :nte, 
                                                                       template_id, st1, st2) 
      else
        uuid = Kt::KtAnalytics.instance.gen_long_uuid
      end
      
      r = send_email_without_kontagent(user_ids, subject, text, fbml)
      
      if !r.blank?
        arg_hash = { 
          's' => @user.id.to_s , 
          'r' => user_ids.is_a?(Array) ? user_ids * "," : user_ids,
          'u' => uuid
        }
      
        arg_hash['t'] = template_id.to_s unless template_id.nil?
        
        Kt::KtAnalytics.instance.kt_outbound_msg('nte', arg_hash)
      end

    end
    
    def publish_user_action_with_kontagent(bundle_id,data={},target_ids=nil,body_general=nil, st1 = nil, st2 = nil)
      if(data != nil)
        data.each_pair do |key,value |
          if key == :image
            uuid, fbml = Kt::KtAnalytics.instance.gen_kt_comm_link(value[:href], :fdp,
                                                                           bundle_id, st1, st2)
            value[:href] = fbml
            data[key] = value # do we even need this line?
          elsif key == :flash
            
          elsif key == :mp3
                    Kt::KtAnalytics.instance.kt_outbound_msg('fdp', arg_hash)
          elsif key == :video
            
          else
            uuid, fbml = Kt::KtAnalytics.instance.gen_kt_comm_link_no_href(value, :fdp, bundle_id, st1, st2)
            data[key] =  fbml
          end
        end
      end

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
