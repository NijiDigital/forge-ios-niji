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
