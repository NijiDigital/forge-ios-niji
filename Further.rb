################################################
# Check certificates and provisioning profiles #
################################################

desc "Checks the expiration date for all certificates and provisioning profiles"
lane :check_certificates_and_profiles do
  Spaceship::Portal.login(ENV.fetch('APPLE_LOGIN', nil)
  Spaceship::Portal.select_team(team_id: (ENV.fetch('TEAM_ID', nil)

  # Fetch all available certificates (includes signing and push profiles)
  certificates = Spaceship::Portal.certificate.all
  certificates.each do |certificate|
    certificate_days_before_expires = (certificate.expires.to_datetime - DateTime.now).to_i
    puts("#{certificate.name} / created by #{certificate.owner_name} : expires in #{certificate_days_before_expires} days")
  end

  # Fetch all available provisioning profiles
  profiles = Spaceship::Portal.provisioning_profile.all
  profiles.each do |profile|
    profile_days_before_expires = (profile.expires - DateTime.now).to_i
    puts("#{profile.name} : expires in #{profile_days_before_expires} days")
  end

  # AppStore provisioning profile
  app_store = Spaceship::Portal.provisioning_profile.app_store.find_by_bundle_id(bundle_id: ENV['BUNDLE_IDENTIFIER']).first
  app_store_days_before_expires = (app_store.expires - DateTime.now).to_i
  puts("#{app_store.name} : expire dans #{app_store_days_before_expires} jours")

  # AdHoc provisioning profile
  ad_hoc = Spaceship::Portal.provisioning_profile.ad_hoc.find_by_bundle_id(bundle_id: ENV['BUNDLE_IDENTIFIER']).first
  ad_hoc_days_before_expires = (ad_hoc.expires - DateTime.now).to_i
  puts("#{ad_hoc.name} : expire dans #{ad_hoc_days_before_expires} jours")
end
