
###########################
# Towncrier               #
###########################

desc 'This lane is the entry point for the other Towncrier lanes. It can be seen as a helper.'
lane :changelog do
  choice = UI.select(
    'Do you want to create a new entry for the changelog or to generate the changelog using the existing entries?', %w[
      logentry changelog
    ]
  )
  case choice
  when 'logentry'
    create_logentry
  when 'changelog'
    generate_changelog
  else
    UI.user_error('Not a valid option')
  end
end

desc 'Create a changelog entry with towncrier to be used in the next changelog generation'
lane :create_logentry do |options|
  ensure_towncrier_installed
  category_choices = CHANGELOG_CATEGORIES

  category = options[:category]
  if category.nil?
    if is_ci?
      UI.user_error!("Missing 'category' parameter")
    else
      category = UI.select('Select category: ', category_choices)
      options[:category] = category
    end
  elsif !category_choices.include?(category)
    UI.user_error!("Invalid 'category' parameter: #{category}")
  end

  issue = options[:issue]
  if issue.nil?
    if is_ci?
      UI.user_error!("Missing 'issue' parameter")
    else
      while issue.to_s.strip.empty?
        issue = UI.input('Enter an issue name: ')
        options[:issue] = issue
      end
    end
  end
  Dir.chdir('..') do
    sh "./fastlane/forge/Scripts/towncrier.sh #{category} #{issue}"
  end
end

desc 'Generate a changelog using all the log entries'
lane :generate_changelog do |options|
  version = get_xcconfig_value(
    path: ENV['APP_VERSION_PATH'],
    name: 'APP_VERSION'
  )

  if version.nil?
    if is_ci?
      UI.user_error!("Missing 'version' parameter")
    else
      version = UI.input('Enter your build version: ')
    end
  end

  unless is_ci?
    version_validated_by_user = false
    until version_validated_by_user
      if UI.confirm("The changelog is going to use the build version '#{version}'. Is it the correct version?")
        options[:version] = version
        version_validated_by_user = true
      else
        version = UI.input('Enter the correct build version: ')
      end
    end
  end

  unless read_changelog(
    changelog_path: './CHANGELOG.md',
    section_identifier: "[#{version}]"
  ).empty?
    UI.user_error!("There is already a changelog for version #{version} in the CHANGELOG. You might consider updating your version first.")
  end

  draft = options[:draft]
  if draft.nil?
    if is_ci?
      # UI.user_error!("Missing 'draft' parameter") # use this instead of the line below to enforce draft parameter in ci
      generate_changelog_from_logentries(version: version)
    else
      create_draft_for_changelog(version: version)
      open_changelog_draft
      if UI.confirm('Check the towncrier/changelog_draft file and confirm if you want its content to be added to the CHANGELOG.md file')
        generate_changelog_from_logentries(version: version)
      else
        UI.error('The changlog was not created.')
      end
    end
  elsif draft == true
    create_draft_for_changelog(version: version)
    open_changelog_draft unless is_ci?
  elsif draft == false
    generate_changelog_from_logentries(version: version)
  else
    UI.user_error!("Invalid 'draft' parameter, must be true or false but was: #{draft}")
  end
end

desc 'Create a draft for an upcoming changelog'
private_lane :create_draft_for_changelog do |values|
  ensure_towncrier_installed
  version = values[:version]
  Dir.chdir('..') do
    sh "towncrier build --draft --version=#{version} > towncrier/changelog_draft;"
  end
end

desc 'Generate changelog from log entries'
private_lane :generate_changelog_from_logentries do |values|
  ensure_towncrier_installed
  version = values[:version]
  files_to_remove = get_logentry_files_for_bash

  Dir.chdir('..') do
    sh("yes n | towncrier build --version=#{version};
        find towncrier/ -type f -maxdepth 1 \\( #{files_to_remove} \\) -delete")
  end
end

desc 'Get all the logentry files for bash command find'
private_lane :get_logentry_files_for_bash do
  is_first = true
  logentry_files = ''
  CHANGELOG_CATEGORIES.each do |category|
    if is_first
      logentry_files += "-name \"*.#{category}\" "
      is_first = false
    else
      logentry_files += " -o -name \"*.#{category}\""
    end
  end
  logentry_files
end

desc 'Open changelog draft'
private_lane :open_changelog_draft do
  Dir.chdir('..') do
    sh 'open towncrier/changelog_draft'
  end
end

desc 'Ensure towncrier is installed before use'
private_lane :ensure_towncrier_installed do
  next if sh('command -v towncrier >/dev/null 2>&1; echo $?').strip == '0'

  if sh('command -v pipx >/dev/null 2>&1; echo $?').strip != '0'
    UI.user_error!('pipx is required to install towncrier but was not found on this machine.')
  end

  UI.important('Towncrier is not installed. Installing it now...')
  sh 'brew install pipx'
  sh 'pipx install towncrier'
end
