insert_into_file "config/environments/development.rb", :before => /^end/ do
  <<-RUBY

  config.file_watcher = ActiveSupport::EventedFileUpdateChecker
  RUBY
end
