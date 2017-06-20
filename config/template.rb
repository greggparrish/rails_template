apply "config/application.rb"
copy_file "config/brakeman.yml"
template "config/database.yml.tt", force: true
remove_file "config/secrets.yml"

template "config/deploy.rb.tt"
template "config/deploy/production.rb.tt"
template "config/deploy/staging.rb.tt"

gsub_file "config/routes.rb", /  # root 'welcome#index'/ do
  '  root "static#home"'
end

copy_file "config/initializers/generators.rb"
copy_file "config/initializers/rotate_log.rb"
copy_file "config/initializers/secret_token.rb"
copy_file "config/initializers/secure_headers.rb"
copy_file "config/initializers/version.rb"

gsub_file "config/initializers/filter_parameter_logging.rb", /\[:password\]/ do
  "%w(password secret session cookie csrf)"
end

apply "config/environments/development.rb"
apply "config/environments/production.rb"
apply "config/environments/test.rb"
template "config/environments/staging.rb.tt"

route 'resources :users'
route 'root "static#home"'
