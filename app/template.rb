### STYLESHEETS
copy_file "app/assets/stylesheets/application.scss"
remove_file "app/assets/stylesheets/application.css"
create_file "app/assets/stylesheets/modules/_modules.scss"
create_file "app/assets/stylesheets/modules/_forms.scss"
create_file "app/assets/stylesheets/modules/_variables.scss"
copy_file "app/assets/stylesheets/modules/_mixins.scss"
copy_file "app/assets/stylesheets/modules/_typography.scss"
copy_file "app/assets/stylesheets/modules/_colors.scss"
create_file "app/assets/stylesheets/partials/_static.scss"
create_file "app/assets/stylesheets/partials/_home.scss"
copy_file "app/assets/stylesheets/partials/_common.scss"
create_file "app/assets/stylesheets/partials/_nav.scss"
copy_file "app/assets/stylesheets/partials/_header.scss"
template "app/assets/stylesheets/partials/_footer.scss"

### JS
copy_file "app/assets/javascripts/application.js", force: true

### CONTROLLERS
copy_file "app/controllers/static_controller.rb"
copy_file "app/controllers/users_controller.rb"
copy_file "app/controllers/application_controller.rb", force: true

### MODELS
copy_file "app/models/user.rb", force: true

### HELPERS
template "app/helpers/application_helper.rb.tt", force: true
copy_file "app/helpers/retina_image_helper.rb"

### VIEWS
copy_file "app/views/layouts/application.html.haml"
remove_file "app/views/layouts/application.html.erb"
remove_file "app/assets/stylesheets/application.html.erb"
copy_file "app/views/shared/_header.html.haml"
template "app/views/shared/_footer.html.haml"
copy_file "app/views/static/home.html.haml"
template "app/views/shared/_nav.html.haml.tt"

### PUNDIT
empty_directory "app/policies"
template "app/policies/application_policy.rb"
copy_file "app/policies/static_policy.rb"
copy_file "app/policies/user_policy.rb"
