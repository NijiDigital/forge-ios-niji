# forge-ios-niji

Set of best practices to have when developing in an iOS project

## Install

```sh
bundle exec fastlane init
```

```sh
cd fastlane
```

```sh
git submodule add https://github.com/NijiDigital/forge-ios-niji.git forge
```

/!\ Use the url HTTPS for the CI/CD /!\

Add import in your Fastfile

```ruby
import 'forge/Forge.rb'
```

## Options Fastlane

`badge:` = true if adding a badge to the application icon (true or false or never)
`env:` = define the environment use (dev, prod, stagging...)
`config:` = define the xcconfig file use (Debug, InHouse, Release...)
`enterprise:` = true if use an provisioning profiles from Apple Developer Enterprise (true or false or never)

for example :

```sh
bundle exec fastlane archive env:dev config:InHouse enterprise:true badge:true
```

## Environment Variables

List of environment variables to use in your Fastfile

ENV['API_KEY_PATH'] = ''.freeze # https://docs.fastlane.tools/app-store-connect-api/
ENV['APP_VERSION_PATH'] = ''.freeze
ENV['DERIVED_DATA_PATH'] = './DerivedData'.freeze
ENV['BUILD_PATH'] = './Build'.freeze
ENV['REPORTS_PATH'] = './Reports'.freeze
ENV['PLIST_PATH'] = ''.freeze
ENV['XCODEGEN_PATH'] = 'project.yml'.freeze

ENV['XCWORKSPACE'] = 'Shiva.xcworkspace'.freeze
ENV['XCPROJECT'] = 'Shiva.xcodeproj'.freeze
ENV['SCHEME'] = 'Shiva'
ENV['APP_NAME'] = 'Shiva'
ENV['TARGET'] = 'Shiva'

ENV['GS_INFO_PLIST_ARCHIVE_PATH'] = '' # The path to your GoogleService-Info.plist file, relative to the path to the archived product (xcarchive)
ENV['FIREBASE_CLI_TOKEN'] = ''

ENV['POESIE_PATH'] = ''.freeze
ENV['SWAGGEN_PATH'] = ''.freeze

## SwiftLint

In your `.swiftlint.yml` file from your project, add this line :

```sh
parent_config: fastlane/forge/.swiftlint_base.yml
```
