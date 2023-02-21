#########################################
# DEVELOPER HELP                       #
#########################################
# Danger : https://danger.systems/ruby/ #
# Regex : https://rubular.com/          #
# Sandbox : http://rubyfiddle.com/      #
#########################################

##################
# WELCOME DANGER #
##################

markdown [
  "👋 Hey, I'm your Danger bot.",
  '👀 I just took a quick look at your Merge Request.',
  '🔄 I will update this comment as you push new commits; so come here to see me again later!'
]

###########################
# Variables
###########################

files_to_check = (git.modified_files + git.added_files).uniq
files_to_lint = (git.modified_files - git.deleted_files) + git.added_files

has_usecase_changes = !git.modified_files.grep(/UseCases/).empty?
has_usecase_creates = !git.added_files.grep(/UseCases/).empty?
has_test_changes = !git.modified_files.grep(/UnitTests/).empty?
has_test_creates = !git.added_files.grep(/UnitTests/).empty?

jira_ref = /(\b((HP|HSA)-)|#)[0-9]+\b/i
entry_re = Regexp.new("^\\+\\* #{jira_ref}")

xcresult_path = 'reports/Socle.xcresult'

#######################################
# Check CHANGELOG entry & App Version
#######################################

release_info = gitlab.branch_for_head.match(%r{^(release)/(.*)$})
if release_info && gitlab.branch_for_base == 'master'

  ## MR from Release Branch to Master Branch? ##

  # Check that GLOBAL_APP_VERSION matches branch name
  version_in_settings = target.build_settings('Release')['GLOBAL_APP_VERSION'] || project.build_settings('Release')['GLOBAL_APP_VERSION']
  if version_in_settings == release_info[2]
    message("You're about to merge a new release `#{release_info[2]}` to master 👍")
  else
    raise("You're about to merge a new release `#{release_info[2]}`, but `GLOBAL_APP_VERSION` is set to `#{version_in_settings}` in your build settings!")
  end

  # Some informative instructions when targetting master or develop
  case gitlab.branch_for_base
  when 'master'
    message("Wait for the CI to turn green before running `bundle exec fastlane release_testflight --env prod` on your machine to push a build to TestFlight.")
    message('Note: Only merge this MR once Apple has approved the new version on the AppStore')
  when 'develop'
    list = [
      "<li>Create a `merge/#{release_info[2]}/develop` branch from `develop`</li>",
      "<li>Merge `#{gitlab.branch_for_head}` into that `merge/#{release_info[2]}/develop` branch</li>",
      "<li>Change the origin of this MR from `#{gitlab.branch_for_head}` to `merge/#{release_info[2]}/develop`, to merge that new branch — with the conflict resolved — into develop instead.</li>"
    ]
    message("In case there is a merge conflict during this MR<br><ul>#{list.join}</ul>")
  end

else
  ## Not a release, just a regular MR ##

  warn('Please include an entry in the CHANGELOG.md') unless git.modified_files.include?('CHANGELOG.md')

  # Check there is a JIRA reference in the MR title, body or branch name
  unless [gitlab.mr_title, gitlab.mr_body].any? { |t| t.match(jira_ref) }
    m = gitlab.branch_for_head.match(jira_ref)
    if m.nil?
      message('No JIRA reference found in title, description or branch name.')
    else
      message("Branch name seems to reference #{m[0].upcase}")
    end
  end
end

#######################################
# Notifies when the Podfile has been updated
#######################################

warn("The Podfile was updated 🫘") unless git.modified_files.include?('Podfile')

#######################################
# Notifies when the Gemfile has been updated
#######################################

warn('The Gemfile was updated 💎') unless git.modified_files.include?('Gemfile')

#######################################
# Notifies when the Brewfile has been updated
#######################################

warn('The Brewfile was updated 🍺') unless git.modified_files.include?('Brewfile')

#######################################
# Notifies when duplicate localizable strings
#######################################

duplicate_localizable_strings.check_localizable_duplicates

#######################################
# Merge request size
#######################################

warn('Big MR') if git.lines_of_code > 500

#######################################
# Merge request title validation
#######################################

warn('MR is classed as Work in Progress') if gitlab.mr_title.include? '[WIP]' || gitlab.mr_title.starts_with?('WIP')

# warn('MR title is too short.') if gitlab.mr_title.count < 5

#######################################
# Files changed and created should includes unit tests
#######################################

warn('Tests were not updated', sticky: false) if has_usecase_changes && !has_test_changes && git.lines_of_code > 20

warn('Tests were not added', sticky: false) if has_usecase_creates && !has_test_creates && git.lines_of_code > 20

#######################################
# Merge request description validation
#######################################

# Mainly to encourage writing up some reasoning about the MR, rather than just leaving a title.
failure 'Please provide a summary in the Merge Request description' if gitlab.mr_body.length < 5

#######################################
# Merge request should have at least one label
#######################################

failure "MR should have at least one label. 🏷'" if gitlab.mr_labels.empty?

#######################################
# Ensure that all MRs have an assignee
#######################################

warn 'This MR does not have any assignees yet.' unless gitlab.mr_json['assignee']

#######################################
# File Checks
#######################################

# Checks for certain rules and warns if needed.
# Some rules can be disabled by using // danger:disable rule_name
#
# Rules:
# - Check to see if any of the modified or added files contains a class which isn't indicated as final (final_class)
# - Check for large files without any // MARK:
# - Check for the usage of unowned self. We rather like to use weak self to be safe.
# - Check for override methods which only implement super calls. These can be removed.
# - Check for public properties or methods which aren't documented (public_docs)

# Sometimes an added file is also counted as modified. We want the files to be checked only once.
(files_to_check - %w[Dangerfile]).each do |file|
  next unless File.file?(file)
  # Only check for classes inside swift files
  next unless File.extname(file).include?('.swift')

  # Will be used to check if we're inside a comment block.
  isCommentBlock = false

  # Will be used to track if we've placed any marks inside our class.
  foundMark = false

  # Collects all disabled rules for this file.
  disabled_rules = []

  filelines = File.readlines(file)
  filelines.each_with_index do |line, index|
    if isCommentBlock
      isCommentBlock = false if line.include?('*/')
    elsif line.include?('/*')
      isCommentBlock = true
    elsif line.include?('danger:disable')
      rule_to_disable = line.split.last
      disabled_rules.push(rule_to_disable)
    else
      # Start our custom line checks
      ## Check for the usage of final class
      if (disabled_rules.include?('final_class') == false) && line.include?('class') && !line.include?('final') && !line.include?('func') && !line.include?('//') && !line.include?('protocol')
        warn('Consider using final for this class or use a struct (final_class)') # , file:, line: index + 1)
      end

      ## Check for methods that only call the super class' method
      if line.include?('override') && line.include?('func') && filelines[index + 1].include?('super') && filelines[index + 2].include?('}')
        warn('Override methods which only call super can be removed') # , file:, line: index + 3)
      end

      ## Check if our line includes a MARK:
      foundMark = true if line.include?('MARK:') && line.include?('//')
    end
  end

  ## Check wether our file is larger than 200 lines and doesn't include any Marks
  if (filelines.count > 200) && (foundMark == false)
    warn('Consider to place some `MARK:` lines for files over 200 lines big.')
  end
end

#######################################
# Run SwiftFormat
#######################################

swiftformat.binary_path = 'Pods/SwiftFormat/CommandLineTool/swiftformat'
swiftformat.check_format(fail_on_error: true)

#######################################
# Run SwiftLint on changed files
#######################################

swiftlint.binary_path = 'Pods/SwiftLint/swiftlint'
swiftlint.max_num_violations = 20
swiftlint.verbose = true
# NOTE: The argument "--force-exclude" is passed to SwiftLint by the danger-swiftlint plugin
#       But this SwiftLint argument doesn't work properly & has issues.
#       So instead, we re-disable it, and filter the list of files manually :-/
files_to_lint.reject! { |f| f.start_with?('Pods/') }
swiftlint.lint_files(files_to_lint,
                     additional_swiftlint_args: '--no-force-exclude')

#######################################
# Run Xcov
#######################################

# Generate report
report = xcov.produce_report(
  scheme: 'Socle',
  workspace: 'Socle.xcworkspace',
  exclude_targets: 'Socle.app',
  minimum_coverage_percentage: 90
)

# Do some custom filtering with the report here

# Post markdown report
xcov.output_report(report)

#######################################
# Run xcode summary
#######################################

xcode_summary.ignored_files = 'Pods/**'
xcode_summary.report = xcresult_path

#######################################
# Run xcprofiler
#######################################

# xcprofiler.report 'Socle'
