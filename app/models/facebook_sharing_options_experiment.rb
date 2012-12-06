class FacebookSharingOptionsExperiment < TimeBandedExperiment

  def initialize whiplash
    super('facebook sharing options', [Time.parse("2012-Nov-02 11:30 -0400")])

    @options = ['facebook_popup', 'facebook_request', 'facebook_recommendation', 'facebook_dialog']
    @whiplash = whiplash
  end

  def spin! member, browser
    return 'facebook_popup' if browser.ie7?

    sharing_option = @whiplash.spin! name_as_of(Time.now), :referred_member, @options
    spin_request_subexperiment sharing_option, member
  end

  def self.applicable_to? signature
    referral_type = signature.reference_type
    return referral_type && SignatureReferral::FACEBOOK_REF_TYPES.values.include?(referral_type)
  end

  def win! signature
    referral_type = win_request_pick_vs_autofill signature.reference_type
    @whiplash.win_on_option! name_as_of_referral(signature), referral_type
  end

  private

  def spin_request_subexperiment sharing_option, member
    request_default = "facebook_request"
    return sharing_option unless sharing_option == request_default
    return request_default unless member.present?
    fb_friend = FacebookFriend.find_by_member_id(member.id)
    fb_friend.present? ?
      (@whiplash.spin! 'facebook request pick vs autofill', :referred_member, [request_default, 'facebook_autofill_request']) :
      request_default
  end

  def win_request_pick_vs_autofill referral_type
    if(referral_type == 'facebook_request' || referral_type == 'facebook_autofill_request')
      @whiplash.win_on_option! 'facebook request pick vs autofill', referral_type
      referral_type = 'facebook_request'
    end
    referral_type
  end

  def name_as_of_referral signature
    referral = signature.referral
    referral_time = referral.created_at if referral
    name = name_as_of referral_time
    if not referral_time
      Rails.logger.debug("Referral time unknown: '+
        'no referer_id for signature #{signature.id}. '+
        'Awarding win for #{signature.reference_type} to default test: #{name}")
    end
    name
  end

end
