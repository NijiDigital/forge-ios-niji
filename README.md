# Forge iOS by Niji

Set of best practices to have when developing in an iOS project

## Installation

Forge relies on [fastlane](https://docs.fastlane.tools/) to automate iOS builds, tests, and deployments. Installation starts with the three steps below, then continues with project configuration (Fastfile import, Forgefile dependencies, SwiftLint).

### 1. Add fastlane to the Gemfile

At the root of your Xcode project, create a `Gemfile` (if it does not already exist) to pin the Ruby tool versions used by the team and CI.

```ruby
source 'https://rubygems.org'

gem 'fastlane'
```

Then install the dependencies:

```sh
bundle install
```

This generates a `Gemfile.lock` that should be committed to the repository. Always use `bundle exec fastlane` instead of `fastlane` alone to ensure the correct version is executed.

### 2. Initialize fastlane

Run initialization from the project root:

```sh
bundle exec fastlane init
```

This command creates the `fastlane/` folder with a `Fastfile` (lane definitions), an `Appfile` (app identifiers), and a `.env.default` (local environment variables). Answer the interactive prompts or keep the defaults; the `Fastfile` can be customized afterwards.

### 3. Add Forge as a Git submodule

Forge is distributed as a [Git submodule](https://git-scm.com/book/en/v2/Git-Tools-Submodules) so it can be versioned independently from the host project and updated in a controlled way.

From the project root, move into the fastlane folder and add the submodule:

```sh
cd fastlane
git submodule add https://github.com/NijiDigital/forge-ios-niji.git forge
cd ..
```

The `fastlane/forge/` folder contains shared lanes, Danger plugins, base SwiftLint configuration, and more. A `.gitmodules` file is created at the repository root; commit it along with the other changes.

To clone a project that already uses Forge:

```sh
git submodule add https://github.com/NijiDigital/forge-ios-niji.git forge
```

:warning: **WARNING**: use the **HTTPS** URL (`https://github.com/...`) rather than SSH when adding the submodule, so CI/CD pipelines can fetch Forge without an SSH key.

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

Forge reads its configuration from environment variables. Add them to `fastlane/.env.default` at the root of the fastlane folder. Fastlane loads this file automatically on every run; commit it to the repository so the whole team shares the same defaults. For secrets (API keys, credentials), prefer CI/CD environment variables or a local `fastlane/.env` file (typically gitignored).

```sh
# Obligatory

APP_VERSION_PATH=
DERIVED_DATA_PATH=./DerivedData
BUILD_PATH=./Build
REPORTS_PATH=./Reports
PLIST_PATH=

XCWORKSPACE=NAME.xcworkspace
XCPROJECT=NAME.xcodeproj
SCHEME=
APP_NAME=
APP_ENVIRONMENT= # Define the environment
TARGET= # For launching the send_metrics lane
TARGET_TEST=

# Firebase
GS_INFO_PLIST_ARCHIVE_PATH=GoogleService-Info.plist # Path to GoogleService-Info.plist, relative to the archived product (xcarchive)
GOOGLE_APPLICATION_CREDENTIALS= # https://firebase.google.com/docs/app-distribution/ios/distribute-fastlane#service-acc-fastlane
FIREBASE_TEST_GROUP= # Tester group ID

# Export plist path (gym)
# iCloud (optional, add iCloudContainerEnvironment key in the export plist)
EXPORT_PLIST_PATH=

# App Store Connect
KEY_ID=
ISSUER_ID=
KEY_FILEPATH=

# Danger
DANGERFILE_PATH=fastlane/forge/Dangerfile
JIRA_REF=/(\b((JIRA)-)|#)[0-9]+\b/i
XCOV_MIN_PERCENTAGE=80.00
XCOV_IGNORE_FILE_PATH=.xcovignore
PERIPHERY_BINARY_PATH=/usr/local/bin/periphery

# Optional
PODFILE_PATH=Podfile
XCODEGEN_PATH=project.yml
POESIE_PATH=
CHANGELOG_PATH=CHANGELOG.md
DEPENDENCY_CHECK_SUPPRESSION_FILE_PATH=
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
