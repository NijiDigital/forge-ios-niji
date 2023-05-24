# Forge iOS by Niji

Set of best practices to have when developing in an iOS project

## Installation

```sh
bundle exec fastlane init
```

```sh
cd fastlane
```

```sh
git submodule add https://github.com/NijiDigital/forge-ios-niji.git forge
```

:warning: WARNING : For add submodule use the url HTTPS for the CI/CD connection

Add import in your `Fastfile` :

```ruby
import 'forge/Forge.rb'
```

Then add `Forgefile` dependencies in your `Gemfile` :

```ruby
# Add these lines at the bottom of the Gemfile

forge_path = File.join(File.dirname(__FILE__), 'fastlane', 'forge', 'Forgefile')
eval_gemfile(forge_path) if File.exist?(forge_path)
```

In your `.swiftlint.yml` file from your project, add this line :

```yml
parent_config: fastlane/forge/.swiftlint_base.yml
```

## Environment Variables

List of environment variables to use in your `Fastfile`

```ruby
# Obligatory

ENV['APP_VERSION_PATH'] = ''.freeze
ENV['DERIVED_DATA_PATH'] = './DerivedData'.freeze
ENV['BUILD_PATH'] = './Build'.freeze
ENV['REPORTS_PATH'] = './Reports'.freeze
ENV['PLIST_PATH'] = ''.freeze

ENV['XCWORKSPACE'] = 'NAME.xcworkspace'.freeze
ENV['XCPROJECT'] = 'NAME.xcodeproj'.freeze
ENV['SCHEME'] = ''
ENV['APP_NAME'] = ''
ENV['APP_ENVIRONMENT'] = '' # Define the environment
ENV['TARGET'] = '' # For launch the lane send_metrics
ENV['TARGET_TEST'] = ''

# Firebase
ENV['GS_INFO_PLIST_ARCHIVE_PATH'] = 'GoogleService-Info.plist'.freeze # The path to your GoogleService-Info.plist file, relative to the path to the archived product (xcarchive)
ENV['FIREBASE_CLI_TOKEN'] = '' # Move this variable in file ".env" at the root of the fastlane folder because this variable is sensible 

# iCloud
ENV['ICLOUD_CONTAINER_ENVIRONMENT'] = 'Production' # 'Development'

# App Store Connect
ENV['KEY_ID'] = ''.freeze
ENV['ISSUER_ID'] = ''.freeze

# Danger
ENV['DANGERFILE_PATH'] = 'fastlane/forge/Dangerfile'.freeze
ENV['JIRA_REF'] = '/(\b((JIRA)-)|#)[0-9]+\b/i'.freeze
ENV['XCOV_MIN_PERCENTAGE'] = '80.00'.freeze
ENV['XCOV_IGNORE_FILE_PATH'] = '.xcovignore'.freeze

# Optional
ENV['DANGERFILE_PATH'] = 'fastlane/forge/Dangerfile'.freeze
ENV['XCODEGEN_PATH'] = 'project.yml'.freeze
ENV['POESIE_PATH'] = ''.freeze
ENV['SWAGGEN_PATH'] = ''.freeze
ENV['CHANGELOG'] = File.read('CHANGELOG.md')
```

## Options Fastlane

- `badge:` true if adding a badge to the application icon (true or false or never)
- `env:` define the environment use (dev, prod, stagging...)
- `config:` define the xcconfig file use (Debug, InHouse, Release...)
- `enterprise:` true if use an provisioning profiles from Apple Developer Enterprise (true or false or never)

for example :

```sh
bundle exec fastlane archive env:dev config:InHouse enterprise:true badge:true
```

## Override method Fastlane

- `config`
- `switch_to_env`
- `before_prepare`
- `after_prepare`