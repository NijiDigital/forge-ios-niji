###########################
# Overrides methods       #
###########################

before_all do
  UI.user_error! 'You must run fastlane using `bundle exec fastlane`' if ENV['BUNDLE_GEMFILE'].nil?
  fastlane_require 'fastlane-plugin-badge'
  fastlane_require 'fastlane-plugin-brew'
  fastlane_require 'fastlane-plugin-changelog'
  fastlane_require 'fastlane-plugin-dependency_check_ios_analyzer'
  fastlane_require 'fastlane-plugin-firebase_app_distribution'
  fastlane_require 'fastlane-plugin-xcconfig'
  fastlane_require 'fastlane-plugin-xcodegen'
end

after_all do |lane|
  next if is_ci

  notification(
    title: "✅ fastlane #{lane}",
    message: "Configuration: #{ENV['CONFIGURATION'] || '(none)'}",
    app_icon: 'https://s3-eu-west-1.amazonaws.com/fastlane.tools/fastlane.png',
    sound: 'default'
  )
end

error do |lane, exception|
  next if is_ci

  notification(
    title: "🛑 fastlane #{lane}",
    message: "Error: #{exception}",
    app_icon: 'https://s3-eu-west-1.amazonaws.com/fastlane.tools/fastlane.png',
    sound: 'hero'
  )
end

###########################
# Requirement             #
###########################

desc 'Install developer tools'
lane :install_developer_tools do
  # Install rbenv for initializing ruby in the project
  brew(command: 'install rbenv') unless is_ci

  # Install ruby-build, an rbenv plugin to easily install any version of ruby
  brew(command: 'install ruby-build') unless is_ci

  # Install pyenv for python initialization in the project
  brew(command: 'install pyenv') unless is_ci

  # Install swiftlint
  brew(command: 'install swiftlint')

  # Install swiftformat
  brew(command: 'install swiftformat')

  # Install periphery
  brew(command: 'install peripheryapp/periphery/periphery')
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
# Prepare                 #
###########################

desc 'Before prepare'
lane :before_prepare do |options|
  # override method
end

desc 'Generate project and install pods'
lane :prepare do |options|
  install_developer_tools

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

###########################
# Test                    #
###########################

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
    fail_build: false
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
    fail_build: false
  )
end

###########################
# Archive                 #
###########################

desc 'Build and archive the app'
lane :archive do |options|
  distribution_method = options[:enterprise] == true ? 'enterprise' : 'ad-hoc'
  export_method = options[:appstore] == true ? 'app-store' : distribution_method

  prepare(options)

  set_build_number unless ENV['PLIST_PATH'].nil?

  badge_icon

  if options[:icloud] == true
    export_options = {
      iCloudContainerEnvironment: ENV['ICLOUD_CONTAINER_ENVIRONMENT']
    }
  end

  if ENV['PODFILE_PATH'].nil?
    gym_with_project(
      export_method: export_method,
      export_options: export_options
    )
  else
    gym_with_workspace(
      export_method: export_method,
      export_options: export_options
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
    export_options: options[:export_options]
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
    export_options: options[:export_options]
  )
end

desc 'Extract the build number from bitrise into environment variables and set in Info.plist'
private_lane :set_build_number do
  UI.message 'Extracting Build number'
  if ENV['BITRISE_BUILD_NUMBER']
    UI.message "==> bitrise build number : #{ENV['BITRISE_BUILD_NUMBER']}"
    set_info_plist_value(
      path: ENV.fetch('PLIST_PATH', nil),
      key: 'CFBundleVersion',
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
# @option add_badge: true|false — defaults to false (which just git-resets the icon to remove the badge)
private_lane :badge_icon do |options|
  if options[:badge]
    brew(command: 'install imagemagick')
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

desc "Install all metrics tools"
private_lane :install_metrics_tools do
  sh('pip3 install --upgrade mobsfscan')
  brew(command: 'install sonar-scanner')
end

desc "Send all metrics to Sonar"
lane :send_metrics do |options|
  test(options)
  install_metrics_tools
  version = get_version_number(
    xcodeproj: ENV.fetch('XCPROJECT', nil),
    target: ENV.fetch('TARGET', nil)
  )
  sonar(project_version: version)
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
    brew(command: 'install swiftgen')
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

####################
# Dependency check #
####################

desc 'OWASP dependency-check iOS analyzers'
lane :dependency_check do
  is_using_spm = ENV['PODFILE_PATH'].nil?
  dependency_check_ios_analyzer(
    skip_spm_analysis: !is_using_spm,
    skip_pods_analysis: is_using_spm,
    project_name: ENV['APP_NAME'],
    output_directory: ENV['REPORTS_PATH'],
    output_types: 'all',
    suppression: ENV['DEPENDENCY_CHECK_SUPPRESSION_FILE_PATH']
  )
end
