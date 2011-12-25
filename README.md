Redmine Installation
-----------

Redmine is a flexible project management web application written using Ruby on Rails framework.

    rake generate_session_store
    RAILS_ENV=production rake db:migrate
    RAILS_ENV=production rake redmine:load_default_data
