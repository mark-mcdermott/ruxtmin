#!/bin/bash
export PATH=/usr/local/bin:$PATH

echo -e "\n\n🦄 BACKEND\n\n"
cd ~/Desktop
rails new back --api --database=postgresql
cd back
rails db:drop db:create
bundle add rack-cors bcrypt jwt
rails active_storage:install
rails db:migrate
cat <<'EOF' | puravida config/initializers/cors.rb ~
Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins "*"
    resource "*",
      headers: :any,
      methods: [:get, :post, :put, :patch, :delete, :options, :head]
  end
end
~
EOF

echo -e "\n\n🦄 Health Controller\n\n"
rails g controller health index
cat <<'EOF' | puravida app/controllers/health_controller.rb ~
class HealthController < ApplicationController
  def index
    render json: { status: 'online' }
  end
end
~
EOF

echo -e "\n\n🦄  Users\n\n"
rails g model user name email avatar:attachment admin:boolean password_digest