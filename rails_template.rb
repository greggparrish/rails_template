# Set path for template files
# ==================================================
template_path = "#{File.dirname(__FILE__)}/templates/"

# Gemfile
# ==================================================
remove_file 'Gemfile'
create_file 'Gemfile', File.read(template_path + 'Gemfile')

# RVM create gemset
# ==================================================
run "cat << EOF >> .rvm-version
  2.2.0"
run "cat << EOF >> .rvm-gemset
  #{app_name}"
run "rvm gemset create #{app_name}"
run "rvm gemset use #{app_name}"
run "gem install bundler"
run "bundle install"

# Database
# ==================================================
remove_file 'config/database.yml'
if yes?("Use Postgres?")
  create_file 'config/database.yml', File.read(template_path + 'config/pg_database.yml')
else
  create_file 'config/database.yml', File.read(template_path + 'config/mysql_database.yml')
end
gsub_file 'config/database.yml', /CHANGEME/, "#{app_name.upcase}"

# Secrets
# ==================================================
remove_file 'config/secrets.yml'
create_file 'config/secrets.yml', File.read(template_path + 'config/secrets.yml')
gsub_file 'config/secrets.yml', /CHANGEME/, "#{app_name.upcase}"

# Helper: title, current page highlighting in nav
# ==================================================
remove_file 'app/helpers/application_helper.rb'
create_file 'app/helpers/application_helper.rb', File.read(template_path + 'helpers/application_helper.rb')
gsub_file 'app/helpers/application_helper.rb', /CHANGEME/, "#{app_name.humanize.titleize}"

# Initialize delayed_job
# ==================================================
generate "delayed_job:active_record"

# Initialize guard
# ==================================================
run "bundle exec guard init rspec"

# Initialize CanCan
# ==================================================
generate "cancan:ability"

# Initialize Simple Form
# ==================================================
generate "simple_form:install --bootstrap"

# Initialize Friendly ID
# ==================================================
generate "friendly_id"

# Set up SCSS dirs and base styles 
# ==================================================
inside 'app/assets/stylesheets' do
  remove_file 'application.css.scss'
  empty_directory "modules"
  empty_directory "partials"
  empty_directory "vendor"
  run "touch modules/_colors.scss, modules/_typography.scss, modules/_variables.scss"
  run "touch partials/_common.scss, partials/_header.scss, partials/_footer.scss, partials/_nav.scss"
  create_file 'application.scss', File.read(template_path + 'scss/application.scss')
end

# HAML: base, header, footer, nav
# ==================================================
inside 'app/views/layouts' do
  remove_file 'application.html.erb'
  create_file 'application.html.haml', File.read(template_path + 'haml/application.html.haml')
  create_file '_footer.html.haml', File.read(template_path + 'haml/_footer.html.haml')
  create_file '_header.html.haml', File.read(template_path + 'haml/_header.html.haml')
  create_file '_nav.html.haml', File.read(template_path + 'haml/_nav.html.haml')
  gsub_file 'application.html.haml', /CHANGEME/, "#{app_name.humanize.titleize}"
  gsub_file '_nav.html.haml', /CHANGEME/, "#{app_name.upcase}"
end

# Add Users
# ==================================================
if yes?("Would you like to add users?")
  generate "devise:install"
  model_name = ask("What would you like the user model to be called? [User]")
  model_name = "User" if model_name.blank?
  generate "devise #{model_name} name:string:uniq"
  rake "db:migrate"

  gsub_file 'config/application.rb', /:password/, ':password, :password_confirmation'
  insert_into_file 'config/initializers/devise.rb', "\n  config.secret_key = ENV['#{app_name.upcase}_DEVISE_SECRET_KEY']", after: "Devise.setup do |config|"
  gsub_file 'app/models/user.rb', /:remember_me/, ':remember_me, :role_id, :avatar, :name'
  gsub_file 'config/routes.rb', /  devise_for :users/ do <<-RUBY
    devise_for :users
    RUBY
  end

  gsub_file 'config/initializers/devise.rb', /please-change-me-at-config-initializers-devise@example.com/, 'CHANGEME@example.com'

  inside 'app/views/devise' do
    get template_path + 'devise/confirmations/new.html.haml', 'confirmations/new.html.haml'
    get template_path + 'devise/mailer/confirmation_instructions.html.haml', 'mailer/confirmation_instructions.html.haml'
    get template_path + 'devise/mailer/reset_password_instructions.html.haml', 'mailer/reset_password_instructions.html.haml'
    get template_path + 'devise/mailer/unlock_instructions.html.haml', 'mailer/unlock_instructions.html.haml'
    get template_path + 'devise/passwords/edit.html.haml', 'passwords/edit.html.haml'
    get template_path + 'devise/passwords/new.html.haml', 'passwords/new.html.haml'
    get template_path + 'devise/registrations/edit.html.haml', 'registrations/edit.html.haml'
    get template_path + 'devise/registrations/new.html.haml', 'registrations/new.html.haml'
    get template_path + 'devise/sessions/new.html.haml', 'sessions/new.html.haml'
    get template_path + 'devise/shared/_links.haml', 'shared/_links.html.haml'
    get template_path + 'devise/unlocks/new.html.haml', 'unlocks/new.html.haml'
  end
end

# Git: Initialize
# ==================================================
remove_file '.gitignore'
create_file '.gitignore', File.read(template_path + "gitignore")
git :init
git add: "."
git commit: %Q{ -m 'Initial commit' }
if yes?("Initialize GitHub repository?")
  git_uri = `git config remote.origin.url`.strip
  unless git_uri.size == 0
    say "Repository already exists:"
    say "#{git_uri}"
  else
    run "curl -u 'greggparrish' -d '{\"name\":\"#{app_name}\"}' https://api.github.com/user/repos"
    git remote: %Q{ add origin git@github.com:greggparrish/#{app_name}.git }
    git push: %Q{ origin master }
  end
end


# Clean
# ==================================================
remove_file 'README.rdoc'
inside 'config' do
  run "find . -type f -exec sed -i '/^\s*[@#]/ d' {} +"
  run "find . -type f -exec sed -i '/^$/ d' {} +"
end

# Print env variables and db commands
# ==================================================
say "
  Add to .bashrc:
  export '#{app_name.upcase}_DB_HOST'='localhost'
  export '#{app_name.upcase}_DB_USER'='#{app_name.downcase}_user'
  export '#{app_name.upcase}_DB_DATABASE'='#{app_name.downcase}_development'
  export '#{app_name.upcase}_DB_PASSWORD'= 'run rake secret'
  export '#{app_name.upcase}_DEVISE_SECRET_KEY'= 'run rake secret'
"
