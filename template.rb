RAILS_REQUIREMENT = "~> 5.0.3"

def apply_template!
  assert_minimum_rails_version
  assert_valid_options
  add_template_repository_to_source_path
  create_db_roles

  template "Gemfile.tt", force: true

  remove_file "README.rdoc"

  template "example.env.tt"
  copy_file "gitignore", ".gitignore", force: true
  template "ruby-version.tt", ".ruby-version"
  prepend_to_file ".ruby-version", RUBY_VERSION
  copy_file "simplecov", ".simplecov"

  copy_file "Capfile"
  copy_file "Guardfile"

  apply "bin/template.rb"
  apply "config/template.rb"
  apply "db/template.rb"
  apply "doc/template.rb"
  apply "lib/template.rb"
  apply "public/template.rb"

  git :init unless preexisting_git_repo?
  empty_directory ".git/safe"

  run_with_clean_bundler_env "bin/setup"
  generate_spring_binstubs

  apply "config.ru.rb"
  apply "app/template.rb"

  binstubs = %w(
    annotate brakeman bundler-audit guard
  )
  run_with_clean_bundler_env "bundle binstubs #{binstubs.join(' ')}"

  gsub_file "config/initializers/devise.rb", '# config.authentication_keys = [:email]' do
    "config.authentication_keys = [ :login ]"
  end

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

def create_db_roles
    @dev_pass ||=
      ask("CREATE ROLE #{app_name.parameterize}_ddb_user WITH LOGIN CREATEDB PASSWORD '';", :blue, echo: false)
    @test_pass ||=
      ask("\n  CREATE ROLE #{app_name.parameterize}_tdb_user WITH LOGIN CREATEDB PASSWORD '';", :blue, echo: false)
    @prod_pass ||=
      ask("\n  CREATE ROLE #{app_name.parameterize}_pdb_user WITH LOGIN CREATEDB PASSWORD '';\n", :blue, echo: false)
end

def git_repo_url
  @git_repo_url ||=
    ask_with_default("What is the git remote URL for this project?", :blue, "skip")
end

def production_hostname
  @production_hostname ||=
    ask_with_default("Production hostname?", :blue, "example.com")
end

def staging_hostname
  @staging_hostname ||=
    ask_with_default("Staging hostname?", :blue, "staging.example.com")
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

def preexisting_git_repo?
  @preexisting_git_repo ||= (File.exist?(".git") || :nope)
  @preexisting_git_repo == true
end

def run_with_clean_bundler_env(cmd)
  return run(cmd) unless defined?(Bundler)
  Bundler.with_clean_env { run(cmd) }
end

apply_template!
