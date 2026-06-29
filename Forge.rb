###########################
# Overrides methods       #
###########################

before_all do
  UI.user_error! 'You must run fastlane using `bundle exec fastlane`' if ENV['BUNDLE_GEMFILE'].nil?
  fastlane_require 'fastlane-plugin-badge'
  fastlane_require 'fastlane-plugin-changelog'
  fastlane_require 'fastlane-plugin-dependency_check_ios_analyzer'
  fastlane_require 'fastlane-plugin-firebase_app_distribution'
  fastlane_require 'fastlane-plugin-xcconfig'
  fastlane_require 'fastlane-plugin-xcodegen'

  update_fastlane unless is_ci
end

###########################
# Developer Tools        #
###########################

desc 'Install for local development'
lane :install_local_developer_tools do
  # Install rbenv for initializing ruby in the project
  brew_install(package: 'rbenv')

  # Install ruby-build, an rbenv plugin to easily install any version of ruby
  brew_install(package: 'ruby-build')

  # Install pipx
  brew_install(package: 'pipx')

  # Install swiftlint
  brew_install(package: 'swiftlint')

  # Install swiftformat
  brew_install(package: 'swiftformat')

  # Install periphery
  brew_install(package: 'peripheryapp/periphery/periphery')
end

private_lane :brew_install do |options|
  package = options[:package]
  sh("NONINTERACTIVE=1 HOMEBREW_NO_AUTO_UPDATE=1 brew install #{package}")
end

###########################
# Prepare                 #
###########################

desc 'Before prepare'
lane :before_prepare do |options|
  # override method
end

# @option env [String] Switch to the specified environment (calls `switch_to_env`)
# @option config [String] Apply the specified Xcode configuration (calls `config`)
desc 'Generate project and install pods'
lane :prepare do |options|
  install_local_developer_tools unless is_ci

  before_prepare(options)

  switch_to_env(options) if options[:env]

  config(options) if options[:config]

  swiftgen unless ENV['SWIFTGEN_PATH'].nil?

  xcodegen(spec: ENV['XCODEGEN_PATH']) unless ENV['XCODEGEN_PATH'].nil?

  cocoapods unless ENV['PODFILE_PATH'].nil?

  after_prepare(options)
end

desc 'After prepare'
lane :after_prepare do |options|
  # override method
end

desc 'Prepare configuration'
lane :config do |options|
  # override method
end

desc 'Switch to the specified environment'
lane :switch_to_env do |options|
  # override method
end

###########################
# Test                    #
###########################

desc 'Merge request analysis'
lane :merge_request do |options|
  prepare(options)

  if ENV['PODFILE_PATH'].nil?
    scan_with_project
  else
    scan_with_workspace
  end

  sonar_scanner

  dependency_track

  danger(dangerfile: ENV['DANGERFILE_PATH']) if is_ci && !ENV['DANGERFILE_PATH'].nil?

  after_test(options)
end

desc 'Runs all the tests'
lane :test do |options|
  prepare(options)

  if ENV['PODFILE_PATH'].nil?
    scan_with_project
  else
    scan_with_workspace
  end

  danger(dangerfile: ENV['DANGERFILE_PATH']) if is_ci && !ENV['DANGERFILE_PATH'].nil?

  after_test(options)
end

lane :after_test do |options|
  # override method
end

desc 'Scan with project for SPM project'
private_lane :scan_with_project do
  scan(
    project: ENV.fetch('XCPROJECT', nil),
    scheme: ENV.fetch('SCHEME', nil),
    clean: false,
    output_types: 'junit',
    result_bundle: true,
    code_coverage: true,
    derived_data_path: ENV.fetch('DERIVED_DATA_PATH', nil),
    output_directory: ENV.fetch('REPORTS_PATH', nil),
    fail_build: ENV.fetch('FAIL_BUILD', 'true') == 'true'
  )
end

desc 'Scan with workspace for CocoaPods project'
private_lane :scan_with_workspace do
  scan(
    workspace: ENV.fetch('XCWORKSPACE', nil),
    scheme: ENV.fetch('SCHEME', nil),
    clean: false,
    output_types: 'junit',
    result_bundle: true,
    code_coverage: true,
    derived_data_path: ENV.fetch('DERIVED_DATA_PATH', nil),
    output_directory: ENV.fetch('REPORTS_PATH', nil),
    fail_build: ENV.fetch('FAIL_BUILD', 'true') == 'true'
  )
end

###########################
# Archive                 #
###########################

# @option env [String] Switch to the specified environment (via `prepare`)
# @option config [String] Apply the specified Xcode configuration (via `prepare`)
# @option badge [Boolean] Add a version/build/environment badge on the app icon (default: false)
# @option enterprise [Boolean] Use enterprise provisioning profiles (default: false, ad-hoc export)
# @option appstore [Boolean] Export for App Store distribution (default: false)
desc 'Build and archive the app'
lane :archive do |options|
  distribution_method = options[:enterprise] == true ? 'enterprise' : 'ad-hoc'
  export_method = options[:appstore] == true ? 'app-store' : distribution_method
  symbols_inclusion = options[:appstore] == true ? false : true

  set_build_number unless ENV['APP_VERSION_PATH'].nil?

  prepare(options)

  badge_icon(options)

  if ENV['PODFILE_PATH'].nil?
    gym_with_project(
      export_method: export_method,
      symbols_inclusion: symbols_inclusion
    )
  else
    gym_with_workspace(
      export_method: export_method,
      symbols_inclusion: symbols_inclusion
    )
  end
end

desc 'Gym with project for SPM project'
private_lane :gym_with_project do |options|
  gym(
    project: ENV.fetch('XCPROJECT', nil),
    scheme: ENV.fetch('SCHEME', nil),
    configuration: ENV.fetch('CONFIGURATION', nil),
    output_name: "#{ENV['APP_NAME']}.ipa",
    export_method: options[:export_method],
    sdk: 'iphoneos',
    silent: true,
    clean: false,
    build_path: ENV.fetch('BUILD_PATH', nil),
    output_directory: ENV.fetch('BUILD_PATH', nil),
    export_options: ENV.fetch('EXPORT_PLIST_PATH', nil),
    include_symbols: options[:symbols_inclusion]
  )
end

desc 'Gym with workspace for CocoaPods project'
private_lane :gym_with_workspace do |options|
  gym(
    workspace: ENV.fetch('XCWORKSPACE', nil),
    scheme: ENV.fetch('SCHEME', nil),
    configuration: ENV.fetch('CONFIGURATION', nil),
    output_name: "#{ENV['APP_NAME']}.ipa",
    export_method: options[:export_method],
    sdk: 'iphoneos',
    silent: true,
    clean: false,
    build_path: ENV.fetch('BUILD_PATH', nil),
    output_directory: ENV.fetch('BUILD_PATH', nil),
    export_options: ENV.fetch('EXPORT_PLIST_PATH', nil),
    include_symbols: options[:symbols_inclusion]
  )
end

desc 'Extract the build number from bitrise into environment variables and set in AppVersion.xcconfig'
private_lane :set_build_number do
  UI.message 'Extracting Build number'
  if ENV['BITRISE_BUILD_NUMBER']
    UI.message "==> bitrise build number : #{ENV['BITRISE_BUILD_NUMBER']}"
    update_xcconfig_value(
      path: ENV.fetch('APP_VERSION_PATH', nil),
      name: 'APP_BUILD_NUMBER',
      value: ENV['BITRISE_BUILD_NUMBER']
    )
  end
end

desc 'Extract the version & build number from the project into environment variables'
private_lane :get_versions_from_project do
  UI.message 'Extracting Version & Build number…'
  current_version = get_xcconfig_value(
    path: ENV.fetch('APP_VERSION_PATH', nil),
    name: 'APP_VERSION'
  )
  current_build_number = get_xcconfig_value(
    path: ENV.fetch('APP_VERSION_PATH', nil),
    name: 'APP_BUILD_NUMBER'
  )
  ENV['VERSION_NUMBER'] = current_version
  ENV['BUILD_NUMBER'] = ENV['BITRISE_BUILD_NUMBER'] || current_build_number
  UI.message "==> v#{ENV['VERSION_NUMBER']} (#{ENV['BUILD_NUMBER']})"
end

desc 'Add a badge to the bottom of the icon with the version/build/env info'
# @option badge [Boolean] Add a version/build/environment badge on the app icon (default: false)
private_lane :badge_icon do |options|
  if options[:badge]
    brew_install(package: 'imagemagick')
    # Reset the icon
    Dir['../**/*.appiconset'].each do |path|
      puts %(Reverting: git checkout -- "#{path}")
      `git checkout -- "#{path}"`
    end

    get_versions_from_project

    # Add the shield.io badge
    add_badge(
      shield: "#{ENV['VERSION_NUMBER']}%20(#{ENV['BUILD_NUMBER']})-#{ENV['APP_ENVIRONMENT']}-blue",
      shield_gravity: 'SouthEast',
      no_badge: true # Remove default "Beta" banner
    )
  end
end

###########################
# Deploy                  #
###########################

desc 'Before OTA upload'
lane :before_ota_upload do |options|
  # override method
end

desc 'Build and distribute OTA to Firebase App Distribution'
lane :ota do |options|
  archive(options)

  before_ota_upload(options)

  changelog = File.read(ENV['CHANGELOG_PATH'])

  firebase_app_distribution(
    googleservice_info_plist_path: ENV.fetch('GS_INFO_PLIST_ARCHIVE_PATH', nil),
    release_notes: changelog,
    service_credentials_file: ENV.fetch('GOOGLE_APPLICATION_CREDENTIALS', nil),
    groups: ENV.fetch('FIREBASE_TEST_GROUP', nil)
  )
end

desc 'Before beta upload'
lane :before_beta_upload do |options|
  # override method
end

desc 'Submit a new Beta Build to Apple TestFlight'
lane :beta do |options|
  options[:appstore] = true

  archive(options)

  before_beta_upload(options)

  app_store_connect_api_key(
    key_id: ENV.fetch('KEY_ID', nil),
    issuer_id: ENV.fetch('ISSUER_ID', nil),
    key_filepath: ENV.fetch('KEY_FILEPATH', nil)
  )

  pilot(
    skip_submission: true,
    skip_waiting_for_build_processing: true
  )
end

###########################
# Metrics / Sonar         #
###########################

desc "Send all metrics to Sonar"
lane :send_metrics do |options|
  test(options)
  sonar_scanner
end

desc "Scan the project with Sonar"
lane :sonar_scanner do
  install_metrics_tools
  version = get_version_number(
    xcodeproj: ENV.fetch('XCPROJECT', nil),
    target: ENV.fetch('TARGET', nil)
  )
  sonar(
    project_version: version
    sonar_login: ENV['SONAR_TOKEN']
  )
end

desc "Install all metrics tools"
private_lane :install_metrics_tools do
  brew_install(package: 'pipx') unless is_ci
  if is_ci
    sh("pip3 install --upgrade mobsfscan")
  else
    sh("pipx install mobsfscan --python python3.13")
  end
  brew_install(package: 'sonar-scanner')
end

###########################
# Poesie                  #
###########################

desc 'Import Localizable.string from POEditor'
lane :poesie do
  sh("bash #{ENV['POESIE_PATH']}")
end

###########################
# SwiftGen                #
###########################

desc 'Generate assets with SwiftGen'
lane :swiftgen do
  Dir.chdir("..") do
    brew_install(package: 'swiftgen')
    sh("swiftgen config run --config #{ENV['SWIFTGEN_PATH']}")
  end
end

###########################
# Versioning              #
###########################

desc "Increment the patch number of APP_VERSION"
lane :increment_patch do
  # get current version with xcconfig plugin
  current_version = get_xcconfig_value(
    path: ENV.fetch('APP_VERSION_PATH', nil),
    name: 'APP_VERSION'
  )
  # parse version number and add 1 to the patch number
  parsed_version = current_version.split(".").map(&:to_i)
  new_version = "#{parsed_version[0]}.#{parsed_version[1]}.#{parsed_version[2] + 1}"

  # update version with xcconfig plugin
  update_xcconfig_value(
    path: ENV.fetch('APP_VERSION_PATH', nil),
    name: 'APP_VERSION',
    value: new_version.to_s
  )
end

desc "Increment the minor number of APP_VERSION"
lane :increment_minor do
  # get current version with xcconfig plugin
  current_version = get_xcconfig_value(
    path: ENV.fetch('APP_VERSION_PATH', nil),
    name: 'APP_VERSION'
  )
  # parse version number, add 1 to the minor number and reset patch number
  parsed_version = current_version.split(".").map(&:to_i)
  new_version = "#{parsed_version[0]}.#{parsed_version[1] + 1}.0"

  # update version with xcconfig plugin
  update_xcconfig_value(
    path: ENV.fetch('APP_VERSION_PATH', nil),
    name: 'APP_VERSION',
    value: new_version.to_s
  )
end

desc "Increment the major number of APP_VERSION"
lane :increment_major do
  # get current version with xcconfig plugin
  current_version = get_xcconfig_value(
    path: ENV.fetch('APP_VERSION_PATH', nil),
    name: 'APP_VERSION'
  )
  # parse version number, add 1 to the major number and reset minor and patch numbers
  parsed_version = current_version.split(".").map(&:to_i)
  new_version = "#{parsed_version[0] + 1}.0.0"

  # update version with xcconfig plugin
  update_xcconfig_value(
    path: ENV.fetch('APP_VERSION_PATH', nil),
    name: 'APP_VERSION',
    value: new_version.to_s
  )
end

###########################
# Dependency Track        #
###########################

desc 'Send SBOM to Dependency Track'
lane :dependency_track do
  unless dependency_track_configured?
    UI.message('Skipping dependency_track: missing Dependency Track environment variables')
    next
  end

  Dir.chdir("..") do
    brew_install(package: 'cdxgen')
    sh("cdxgen --server-url #{ENV['DEPENDENCY_TRACK_URL']} --project-id #{ENV['DEPENDENCY_TRACK_PROJECT_ID']} --api-key #{ENV['DEPENDENCY_TRACK_API_KEY']}")
  end
end

private_lane :dependency_track_configured? do
  required_variables = %w[
    DEPENDENCY_TRACK_URL
    DEPENDENCY_TRACK_PROJECT_ID
    DEPENDENCY_TRACK_API_KEY
  ]

  required_variables.all? { |variable| !ENV[variable].to_s.strip.empty? }
end
