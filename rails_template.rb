RAILS_REQUIREMENT = "~> 5.1.0"

def apply_template!
  assert_minimum_rails_version
  assert_valid_options
  add_template_repository_to_source_path

  template "Gemfile.tt", :force => true

  template "DEPLOYMENT.md.tt"
  template "PROVISIONING.md.tt"
  template "README.md.tt", :force => true
  remove_file "README.rdoc"

  template "example.env.tt"
  copy_file "gitignore", ".gitignore", :force => true
  copy_file "overcommit.yml", ".overcommit.yml"
  template "ruby-version.tt", ".ruby-version"
  template "ruby-gemset.tt", ".ruby-gemset"
  copy_file "simplecov", ".simplecov"
  copy_file "Guardfile"

  init_rvm

  apply "config.ru.rb"

  git :init unless preexisting_git_repo?
  empty_directory ".git/safe"

  run "bin/setup"
  generate_spring_binstubs

  binstubs = %w(
    annotate brakeman bundler-audit guard rubocop terminal-notifier
  )
  run "bundle binstubs #{binstubs.join(' ')}"

  template "rubocop.yml.tt", ".rubocop.yml"
  run_rubocop_autocorrections

  unless preexisting_git_repo?
    git :add => "-A ."
    git :commit => "-n -m 'Set up project'"
    git :checkout => "-b development"
    if git_repo_specified?
      git :remote => "add origin #{git_repo_url.shellescape}"
      git :push => "-u origin --all"
    end
  end
end

require "fileutils"
require "shellwords"

def add_template_repository_to_source_path
  if __FILE__ =~ %r{\Ahttps?://}
    source_paths.unshift(tempdir = Dir.mktmpdir("rails-template-"))
    at_exit { FileUtils.remove_entry(tempdir) }
    git :clone => [
      "--quiet",
      "https://github.com/greggparrish/rails-template.git",
      tempdir
    ].map(&:shellescape).join(" ")
  else
    source_paths.unshift(File.dirname(__FILE__))
  end
end

def assert_minimum_rails_version
  requirement = Gem::Requirement.new(RAILS_REQUIREMENT)
  rails_version = Gem::Version.new(Rails::VERSION::STRING)
  return if requirement.satisfied_by?(rails_version)

  prompt = "This template requires Rails #{RAILS_REQUIREMENT}. "\
           "You are using #{rails_version}. Continue anyway?"
  exit 1 if no?(prompt)
end

# Bail out if user has passed in contradictory generator options.
def assert_valid_options
  valid_options = {
    :skip_gemfile => false,
    :skip_bundle => false,
    :skip_git => false,
    :skip_test_unit => false,
    :edge => false
  }
  valid_options.each do |key, expected|
    next unless options.key?(key)
    actual = options[key]
    unless actual == expected
      fail Rails::Generators::Error, "Unsupported option: #{key}=#{actual}"
    end
  end
end

def git_repo_url
  @git_repo_url ||=
    ask_with_default("What is the git remote URL for this project?", :blue, "skip")
end

def ask_with_default(question, color, default)
  return default unless $stdin.tty?
  question = (question.split("?") << " [#{default}]?").join
  answer = ask(question, color)
  answer.to_s.strip.empty? ? default : answer
end

def git_repo_specified?
  git_repo_url != "skip" && !git_repo_url.strip.empty?
end

def init_rvm
  run "rvm gemset create #{app_name}"
  run "rvm gemset use #{app_name}"
end

def preexisting_git_repo?
  @preexisting_git_repo ||= (File.exist?(".git") || :nope)
  @preexisting_git_repo == true
end

apply_template!
