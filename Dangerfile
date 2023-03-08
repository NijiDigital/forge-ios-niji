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

#######################################
# Check CHANGELOG entry & App Version #
#######################################

release_info = gitlab.branch_for_head.match(%r{^(release)/(.*)$})
if release_info && gitlab.branch_for_base == 'master'

  ## MR from Release Branch to Master Branch? ##

  # Check that APP_VERSION matches branch name
  version_in_settings = target.build_settings('Release')['APP_VERSION'] || project.build_settings('Release')['APP_VERSION']
  if version_in_settings == release_info[2]
    message("You're about to merge a new release `#{release_info[2]}` to master 👍")
  else
    raise("You're about to merge a new release `#{release_info[2]}`, but `APP_VERSION` is set to `#{version_in_settings}` in your build settings!")
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
  unless ENV['JIRA_REF'].nil?
    unless [gitlab.mr_title, gitlab.mr_body].any? { |t| t.match(ENV['JIRA_REF']) }
      m = gitlab.branch_for_head.match(ENV['JIRA_REF'])
      if m.nil?
        message('No JIRA reference found in title, description or branch name.')
      else
        message("Branch name seems to reference #{m[0].upcase}")
      end
    end
  end
end

##############################################
# Notifies when the Podfile has been updated # 
##############################################

message("The Podfile was updated 🫘") unless git.modified_files.include?('Podfile')

##############################################
# Notifies when the Gemfile has been updated #
##############################################

message('The Gemfile was updated 💎') unless git.modified_files.include?('Gemfile')

######################
# Merge request size #
######################

warn('Big MR') if git.lines_of_code > 500

##################################
# Merge request title validation #
##################################

warn('MR is classed as Work in Progress') if gitlab.mr_title.include? '[WIP]' || gitlab.mr_title.starts_with?('WIP')

########################################################
# Files changed and created should includes unit tests #
########################################################

has_usecase_changes = !git.modified_files.grep(/UseCases/).empty?
has_usecase_creates = !git.added_files.grep(/UseCases/).empty?
has_test_changes = !git.modified_files.grep(/UnitTests/).empty?
has_test_creates = !git.added_files.grep(/UnitTests/).empty?

warn('Tests were not updated', sticky: false) if has_usecase_changes && !has_test_changes && git.lines_of_code > 20
warn('Tests were not added', sticky: false) if has_usecase_creates && !has_test_creates && git.lines_of_code > 20

########################################
# Merge request description validation #
########################################

# Mainly to encourage writing up some reasoning about the MR, rather than just leaving a title.
failure 'Please provide a summary in the Merge Request description' if gitlab.mr_body.length < 5

################################################
# Merge request should have at least one label #
################################################

warn "MR should have at least one label. 🏷'" if gitlab.mr_labels.empty?

########################################
# Ensure that all MRs have an assignee #
########################################

warn 'This MR does not have any assignees yet.' unless gitlab.mr_json['assignee']

###############
# File Checks #
###############

#### HELPER METHODS

def lineContainsPublicPropertyMethodClassOrStruct(line)
	if lineIsPropertyMethodClassOrStruct(line) and line.include?("public")
		return true
	end
	return false
end

def lineIsPropertyMethodClassOrStruct(line)
	if line.include?("var") or line.include?("let") or line.include?("func") or line.include?("class") or line.include?("struct")
		return true
	end
	return false
end

def lineIncludesDocumentComment(line)
	if line.include?("///") or line.include?("*/")
		return true
	end
	return false
end

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
files_to_check = (git.modified_files + git.added_files).uniq
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
        warn("Consider using final for this class or use a struct (final_class)", file: file, line: index+1)
      end

      ## Check for the usage of unowned self
			if line.include?("unowned self")
				warn("It's safer to use weak instead of unowned", file: file, line: index+1) 
			end
      
      ## Check for methods that only call the super class' method
      if line.include?('override') && line.include?('func') && filelines[index + 1].include?('super') && filelines[index + 2].include?('}')
        warn("Override methods which only call super can be removed", file: file, line: index+3) 
      end

      ## Check if our line includes a MARK:
      foundMark = true if line.include?('MARK:') && line.include?('//')

      ## Check for public properties which aren't commented
			if disabled_rules.include?("public_docs") == false and lineContainsPublicPropertyMethodClassOrStruct(line) && lineIncludesDocumentComment(filelines[index-1]) == false
				warn("Public properties, methods, classes or structs should be documented. Make use of `///` or `/* */` so it will show up inside the docs. (public_docs)", file: file, line: index+1) 
			end
    end
  end

  ## Check wether our file is larger than 200 lines and doesn't include any Marks
  if (filelines.count > 200) && (foundMark == false)
    warn('Consider to place some `MARK:` lines for files over 200 lines big.')
  end
end

###################
# Run SwiftFormat #
###################

swiftformat.binary_path = '/usr/local/bin/swiftformat'
swiftformat.check_format(fail_on_error: true)

##################################
# Run SwiftLint on changed files #
##################################

swiftlint.binary_path = '/usr/local/bin/swiftlint'
swiftlint.max_num_violations = 20

############
# Run Xcov #
############

xcov.report(
  workspace: ENV['XCWORKSPACE'],
  scheme: ENV['SCHEME'],
  minimum_coverage_percentage: ENV['MIN_XCOV_PERCENTAGE'].to_f,
  include_targets: "#{ENV['APP_NAME']}.app",
  xccov_file_direct_path: "#{ENV['REPORTS_PATH']}/#{ENV['SCHEME']}.xcresult"
)

###########################
# Display report UnitTest #
###########################

junit.parse "#{ENV['REPORTS_PATH']}/report.junit"
junit.report

##################
# Run periphery  #
##################

periphery.binary_path = '/usr/local/bin/periphery'
periphery.scan(
  workspace: ENV['XCWORKSPACE'],
  schemes: ENV['SCHEME'],
  targets: ENV['SCHEME'],
  skip_build: true,
  index_store_path: "#{ENV['DERIVED_DATA_PATH']}/Index.noindex/DataStore" # './DerivedData/Index/DataStore' in Xcode 13 or earlier.
)