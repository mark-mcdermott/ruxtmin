Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins 'http://localhost:3001', 'https://app-frontend.fly.dev'
    resource "*",
    headers: :any,
    expose: ['access-token', 'expiry', 'token-type', 'Authorization'],
    methods: [:get, :patch, :put, :delete, :post, :options, :show]
  end
end