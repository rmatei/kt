# Kontagent facebooker version 0.1.6
module Facebooker
  module Rails
    class Publisher
      
      def template(arg)
        @template = arg
      end

      def subtype1(arg)
        @subtype1 = arg
      end
      
      def subtype2(arg)
        @subtype2 = arg
      end
      
      
      def send_message_with_kontagent(method)
        @recipients = @recipients.is_a?(Array) ? @recipients : [@recipients]
        if from.nil? and @recipients.size==1 and ! announcement_notification?(from,_body)
          @from = @recipients.first
        end
        # notifications can 
        # omit the from address
        raise InvalidSender.new("Sender must be a Facebooker::User") unless from.is_a?(Facebooker::User) || announcement_notification?(from,_body)
        case _body
        when Facebooker::Feed::TemplatizedAction,Facebooker::Feed::Action
          from.publish_action(_body)
        when Facebooker::Feed::Story
          @recipients.each {|r| r.publish_story(_body)}
        when Notification
          (from.nil? ? Facebooker::Session.create : from.session).send_notification(@recipients,_body.fbml, nil, @from, @template, @subtype1, @subtype2)
        when Email
          from.session.send_email(@recipients, 
                                  _body.title, 
                                  _body.text, 
                                  _body.fbml,
                                  @template,
                                  @subtype1,
                                  @subtype2)
        when Profile
          # If recipient and from aren't the same person, create a new user object using the
          # userid from recipient and the session from from
          if @from != @recipients.first
            @from = Facebooker::User.new(Facebooker::User.cast_to_facebook_id(@recipients.first),from.session) 
          end
          from.set_profile_fbml(_body.profile, _body.mobile_profile, _body.profile_action, _body.profile_main)
        when Ref
          @from.session.server_cache.set_ref_handle(_body.handle,_body.fbml)
        when UserAction
          @from.session.publish_user_action(_body.template_id || FacebookTemplate.for(method) ,_body.data,_body.target_ids,_body.body_general)
        else
          raise UnspecifiedBodyType.new("You must specify a valid send_as")
        end
      end
      
      alias_method_chain :send_message, :kontagent
 
    end
  end
end
