require 'kt/kt_analytics'
require 'ruby-debug'

module Facebooker
  class User
    def set_profile_fbml_with_kontagent(profile_fbml, mobile_fbml, profile_action_fbml, profile_main = nil, subtype1=nil, subtype2=nil)
      profile_fbml = Kt::KtAnalytics.instance.gen_profile_fbml_link(profile_fbml, subtype1, subtype2, uid) if !profile_fbml.nil?
      mobile_fbml = Kt::KtAnalytics.instance.gen_profile_fbml_link(mobile_fbml, subtype1, subtype2, uid) if !mobile_fbml.nil?
      profile_action_fbml = Kt::KtAnalytics.instance.gen_profile_fbml_link(profile_action_fbml, subtype1, subtype2, uid) if !profile_action_fbml.nil?
      profile_main = Kt::KtAnalytics.instance.gen_profile_fbml_link(profile_main, subtype1, subtype2, uid) if !profile_main.nil?
      
      set_profile_fbml_without_kontagent(profile_fbml, mobile_fbml, profile_action_fbml, profile_main)
      
      Kt::KtAnalytics.instance.kt_profile_setFBML_send(uid, subtype1, subtype2)
    end
    
    def set_profile_info_with_kontagent(title, info_fields, format = :text, subtype1=nil, subtype2=nil)
      info_fields = Kt::KtAnalytics.instance.gen_profile_info_link(info_fields, uid, subtype1, subtype2)
      set_profile_info_without_kontagent(title, info_fields, format)
      Kt::KtAnalytics.instance.kt_profile_setInfo_send(uid, subtype1, subtype2)
    end

    alias_method_chain :set_profile_fbml, :kontagent
    alias_method_chain :set_profile_info, :kontagent
    
    end
  
end
