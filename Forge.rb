fastlane_require 'fastlane-plugin-badge'
fastlane_require 'fastlane-plugin-brew'
fastlane_require 'fastlane-plugin-changelog'
fastlane_require 'fastlane-plugin-firebase_app_distribution'
fastlane_require 'fastlane-plugin-xcconfig'
fastlane_require 'fastlane-plugin-xcodegen'

###########################
# Requirement             #
###########################

desc 'Install developer tools'
lane :install_developer_tools do
  # Installe rbenv pour l'initialisation de ruby dans le projet
  brew(command: 'install rbenv')

  # Installe ruby-build, un plugin de rbenv pour installer facilement n'importe quelle version de ruby
  brew(command: 'install ruby-build')

  # Installe pyenv pour l'initialisation de python dans le projet
  brew(command: 'install pyenv')

  # Installe swiftlint
  brew(command: 'install swiftlint')

  # Installe swiftformat
  brew(command: 'install swiftformat')
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
  before_prepare(options)
  xcodegen(spec: ENV.fetch('XCODEGEN_PATH', nil))
  cocoapods
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

  scan(
    workspace: ENV.fetch('XCWORKSPACE', nil),
    scheme: ENV.fetch('SCHEME', nil),
    clean: false,
    result_bundle: true,
    code_coverage: true,
    derived_data_path: ENV.fetch('DERIVED_DATA_PATH'),
    output_directory: ENV.fetch('REPORTS_PATH')
  )

  after_test(options)
end

lane :after_test do |options|
  # override method
end

###########################
# Archive                 #
###########################

desc 'Build and archive the app'
lane :archive do |options|

  distribution_method = options[:enterprise] == true ? 'enterprise' : 'ad-hoc'
  export_method = options[:appstore] == true ? 'app-store' : distribution_method

  prepare(options)

  set_build_number

  badge_icon

  gym(
    workspace: ENV.fetch('XCWORKSPACE', nil),
    scheme: ENV.fetch('SCHEME', nil),
    configuration: ENV.fetch('CONFIGURATION', nil),
    output_name: "#{ENV['APP_NAME']}.ipa",
    export_method: export_method,
    sdk: 'iphoneos',
    silent: true,
    clean: false,
    output_directory: ENV.fetch('IPA_OUTPUT_DIR', nil)
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
    path: APP_VERSION_PATH,
    name: 'APP_VERSION'
  )
  current_build_number = get_xcconfig_value(
    path: APP_VERSION_PATH,
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

desc 'Build and distribute OTA to Firebase App Distribution'
lane :ota do |options|
  archive(
    config: options[:config],
    env: options[:env],
    enterprise: options[:enterprise],
    appstore: false
  )

  changelog = '' # TODO

  firebase_app_distribution(
    app: ENV.fetch('FIREBASE_APP', nil),
    release_notes: changelog,
    firebase_cli_token: ENV.fetch('FIREBASE_CLI_TOKEN', nil)
  )
end

desc 'Submit a new Beta Build to Apple TestFlight'
lane :beta do |options|

  archive(
    enterprise: false,
    appstore: true
  )

  pilot(
    api_key_path: ENV.fetch('API_KEY_PATH', nil),
    skip_submission: true,
    skip_waiting_for_build_processing: true
  )
end

###########################
# Metrics / Sonar         #
###########################

desc "Install all metrics tools"
private_lane :install_metrics_tools do
  sh('pip install mobsfscan')
  brew(command: 'install swiftlint')
  brew(command: 'install peripheryapp/periphery/periphery')
  brew(command: 'install sonar-scanner')
end

desc "Send all metrics to Sonar"
lane :send_metrics do
  prepare
  test
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

desc 'Import Loacalizable.string from POEditor'
lane :poesie do
  sh("bash #{ENV['POESIE_PATH']}")
end

###########################
# Swagger                 #
###########################

desc 'Generate network stack with SwagGen'
lane :swaggen do
  brew(command: 'install mint')
  sh('mint install yonaskolb/SwagGen')
  sh("bash #{ENV['SWAGGEN_PATH']}")
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
