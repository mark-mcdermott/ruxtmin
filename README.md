# Ruxtmin - Rails 7 Nuxt 2 Admin Boilerplate (With Active Storage Avatars)

Nuxt 2 frontend, Rails 7 backend API and a simple implementation of Rail's Active Storage for uploading and displaying avatars.

## Requirements
This readme uses a small custom bash command called [puravida](#user-content-puravida).

## BACKEND
- `cd ~/Desktop`
- `rails new back --api --database=postgresql`
- `cd back`
- create database
  - if first time doing this: `rails db:create`
  - if database already exists: `rails db:drop db:create`
- `bundle add rack-cors bcrypt jwt`
- `rails active_storage:install`
- `rails db:migrate`
- `puravida config/initializers/cors.rb ~`
```
Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins "*"
    resource "*",
      headers: :any,
      methods: [:get, :post, :put, :patch, :delete, :options, :head]
  end
end
~
```

### Health Controller
- `rails g controller health index`
- `puravida app/controllers/health_controller.rb ~`
```
class HealthController < ApplicationController
  def index
    render json: { status: 'online' }
  end
end
~
```

### Users
- `rails g model user name email avatar:attachment admin:boolean password_digest`
- change the migration file (`db/migrate/<timestamp>_create_users.rb`) to:
```
class CreateUsers < ActiveRecord::Migration[7.0]
  def change
    create_table :users do |t|
      t.string :name, null: false
      t.string :email, null: false, index: { unique: true }
      t.boolean :admin, null: false, default: false
      t.string :password_digest
      t.timestamps
    end
  end
end
```
- `rails db:migrate`
- `puravida app/models/user.rb ~`
```
class User < ApplicationRecord
  has_one_attached :avatar
  has_secure_password
end
~
```
- `puravida app/controllers/users_controller.rb ~`
```
class UsersController < ApplicationController
  
  def index
    @users = User.all.map do |u|
      { :id => u.id, :name => u.name, :email => u.email, :avatar => url_for(u.avatar), :admin => u.admin }
    end
    render json: @users
  end

  def show
    @user = User.find(params[:id])
    render json: {
      id: @user.id,
      name: @user.name,
      email: @user.email,
      avatar: url_for(@user.avatar),
      admin: @user.admin
    }
  end
  
  def create
    user = User.create user_params
    attach_main_pic(user) if admin_params[:avatar].present?
    if user.save
      render json: user, status: 200
    else
      render json: user, status: 400
    end
  end

  private

  def attach_main_pic(user)
    user.avatar.attach(admin_params[:avatar])
  end

  def user_params
    admin = admin_params[:admin].present? ? admin_params[:admin] : false
    {
      name: admin_params[:name],
      email: admin_params[:email],
      admin: admin,
      password: admin_params[:password],
    }
  end

  def admin_params
    params.permit(
      :name,
      :email,
      :avatar,
      :admin,
      :password
    )
  end
end
~
```
- `puravida config/routes.rb ~`
```
Rails.application.routes.draw do
  resources :users
  get "health", to: "health#index"
end
~
```

### Seeds
- copy `assets` folder into `app` folder
- `puravida db/seeds.rb ~`
```
user = User.create(name: "Michael Scott", email: "michaelscott@dundermifflin.com", admin: "true", password: "password")
user.avatar.attach(io: URI.open("#{Rails.root}/app/assets/office-avatars/michael-scott.png"), filename: "michael-scott.png")
user.save!
user = User.create(name: "Jim Halpert", email: "jimhalpert@dundermifflin.com", admin: "false", password: "password")
user.avatar.attach(io: URI.open("#{Rails.root}/app/assets/office-avatars/jim-halpert.png"), filename: "jim-halpert.png")
user.save!
user = User.create(name: "Pam Beesly", email: "pambeesly@dundermifflin.com", admin: "false", password: "password")
user.avatar.attach(io: URI.open("#{Rails.root}/app/assets/office-avatars/pam-beesly.png"), filename: "jim-halpert.png")
user.save!
~
```
- `rails db:seed`

### Backend Auth
- `puravida app/controllers/application_controller.rb ~`
```
class ApplicationController < ActionController::API
  SECRET_KEY_BASE = Rails.application.credentials.secret_key_base
  before_action :require_login
  rescue_from Exception, with: :response_internal_server_error
  
  def user_from_token
    user = current_user.slice(:id,:email,:name,:admin)
    user['admin'] = user['admin'] == 't' ? 'true' : 'false'
    render json: { data: user, status: 200 }
  end

  def require_login
    response_unauthorized if current_user.blank?
  end
  
  def current_user
    if decoded_token.present?
      user_id = decoded_token[0]['user_id']
      @user = User.find_by(id: user_id)
    else
      nil
    end
  end
  
  def encode_token(payload)
    JWT.encode payload, SECRET_KEY_BASE, 'HS256'
  end
  
  def decoded_token
    if auth_header
      token = auth_header.split(' ')[1]
      begin
        JWT.decode token, SECRET_KEY_BASE, true, { algorithm: 'HS256' }
      rescue JWT::DecodeError
        []
      end
    end
  end
  
  def response_unauthorized
    render status: 401, json: { status: 401, message: 'Unauthorized' }
  end
  
  def response_internal_server_error
    render status: 500, json: { status: 500, message: 'Internal Server Error' }
  end
  
  private 
  
    def auth_header
      request.headers['Authorization']
    end
end
~
```
- `rails g controller Authentications`
- `puravida app/controllers/authentications_controller.rb ~`
```
class AuthenticationsController < ApplicationController
  skip_before_action :require_login
  
  def create
    user = User.find_by(email: params[:email])
    if user && user.authenticate(params[:password])
      payload = { user_id: user.id, email: user.email }
      token = encode_token(payload)
      render json: { data: token, status: 200, message: 'You are logged in successfully' }
    else
      response_unauthorized
    end
  end
end
~
```
- `puravida app/controllers/users_controller.rb ~`
```
class UsersController < ApplicationController
  skip_before_action :require_login, only: :create
  
  def index
    @users = User.all.map do |u|
      { :id => u.id, :name => u.name, :email => u.email, :avatar => url_for(u.avatar), :admin => u.admin }
    end
    render json: @users
  end

  def show
    @user = User.find(params[:id])
    render json: {
      id: @user.id,
      name: @user.name,
      email: @user.email,
      avatar: url_for(@user.avatar),
      admin: @user.admin
    }
  end
  
  def create
    user = User.create user_params
    attach_main_pic(user) if admin_params[:avatar].present?
    if user.save
      render json: user, status: 200
    else
      render json: user, status: 400
    end
  end

  private

  def attach_main_pic(user)
    user.avatar.attach(admin_params[:avatar])
  end

  def user_params
    admin = admin_params[:admin].present? ? admin_params[:admin] : false
    {
      name: admin_params[:name],
      email: admin_params[:email],
      admin: admin,
      password: admin_params[:password],
    }
  end

  def admin_params
    params.permit(
      :name,
      :email,
      :avatar,
      :admin,
      :password
    )
  end
end
~
```
- `puravida app/controllers/health_controller.rb ~`
```
class HealthController < ApplicationController
  skip_before_action :require_login
  def index
    render json: { status: 'online' }
  end
end
~
```
- `puravida config/routes.rb ~`
```
Rails.application.routes.draw do
  resources :users
  get "health", to: "health#index"
  post "login", to: "authentications#create"
  get "me", to: "application#user_from_token"
end
~
```

- `rails s`

## FRONTEND

### Setup
- (in a separate terminal tab)
- `cd ~/Desktop`
- `(sleep 0.5; printf "\n"; sleep 0.5; printf "\n"; sleep 0.5; echo -n $'\033[1B'; printf "\n"; sleep 0.5; printf "\n"; sleep 0.5; printf "\n"; sleep 0.1; echo -n $'\x20'; sleep 0.1; printf "\n"; sleep 0.5; printf "\n"; sleep 0.5; printf "\n"; sleep 0.5; echo -n $'\033[1B'; printf "\n"; sleep 0.5; printf "\n"; sleep 0.5; printf "\n"; sleep 0.5; printf "\n"; sleep 0.5; echo -n $'\033[1B'; printf "\n";) | npx create-nuxt-app front`
  - Project name: `front`
  - Programming language: JavaScript
  - Package manager: Npm
  - UI framework: None
  - Template engine: HTML
  - Nuxt.js modules: Axios
  - Linting tools: none
  - Testing framework: None
  - Rendering mode: Single Page App
  - Deployment target: Server
  - Development tools: none
  - What is your GitHub username: mark-mcdermott
  - Version control system: None
  - (takes 30 seconds to setup starter files)
- `cd front`
- `npm install @picocss/pico @nuxtjs/auth@4.5.1`
- `npm install --save-dev sass sass-loader@10 @picocss/pico`
- add `"sass": "node-sass ./public/scss/main.scss ./public/css/style.css -w"` to the `scripts` section of your `package.json` file
- `puravida assets/scss/main.scss ~`
```
@import "node_modules/@picocss/pico/scss/pico.scss";

// Pico overrides 
$primary-500: #e91e63;
~
```
- `puravida nuxt.config.js ~`
```
let development = process.env.NODE_ENV !== 'production'
export default {
  ssr: false,
  head: { title: 'front', htmlAttrs: { lang: 'en' },
    meta: [ { charset: 'utf-8' },
      { name: 'viewport', content: 'width=device-width, initial-scale=1' },
      { hid: 'description', name: 'description', content: '' },
      { name: 'format-detection', content: 'telephone=no' }
    ], link: [{ rel: 'icon', type: 'image/x-icon', href: '/favicon.ico' }]
  },
  css: ['@/assets/scss/main.scss'],
  components: true,
  buildModules: [],
  router: { middleware: ['auth'] },
  modules: ['@nuxtjs/axios', '@nuxtjs/auth'],
  axios: { baseURL: development ? 'http://localhost:3000' : 'https://ruxtmin-back.fly.dev/' },
  server: { port: development ? 3001 : 3000 },
  auth: {
    strategies: {
      local: {
        endpoints: {
          login: { url: 'login', method: 'post', propertyName: 'data' },
          logout: false,
          user: { url: 'me', method: 'get', propertyName: 'data' }
        }
      }
    },
    redirect: {
      login: '/log-in',
      logout: '/',
      home: '/'
    }
  }
}
~
```
- `rm -rf components/*`
- `y`

## New User Page
- `puravida components/NewUserForm.vue ~`
```
<template>
  <section>
    <form enctype="multipart/form-data">
      <p>Name: </p><input v-model="name">
      <p>Email: </p><input v-model="email">
      <p>Avatar: </p><input type="file" ref="inputFile" @change=uploadAvatar()>
      <p>Password: </p><input type="password" v-model="password">
      <button @click.prevent=createUser>Create User</button>
    </form>
  </section>
</template>

<script>
export default {
  data () {
    return {
      name: "",
      email: "",
      avatar: null,
      password: ""
    }
  },
  methods: {
    uploadAvatar: function() {
      this.avatar = this.$refs.inputFile.files[0];
    },
    createUser: function() {
      const params = {
        'name': this.name,
        'email': this.email,
        'avatar': this.avatar,
        'password': this.password,
      }
      let payload = new FormData()
      Object.entries(params).forEach(
        ([key, value]) => payload.append(key, value)
      )
      this.$axios.$post('users', payload)
    }
  }
}
</script>
~
```
- `puravida pages/users/new.vue ~`
```
<template>
  <main class="container">
    <h1>New User</h1>
    <NewUserForm />
  </main>
</template>
~
```

### Users Page
- `puravida components/UsersList.vue ~`
```
<template>
  <section>
    <div v-for="user in users" :key="user.id">
      <article>
        <h2><NuxtLink :to="`users/${user.id}`">{{ user.name }}</NuxtLink></h2>
        <p>id: {{ user.id }}</p>
        <p>email: {{ user.email }}</p>
        <p>avatar:</p>
        <img :src="user.avatar" />
        <p>admin: {{ user.admin }}</p>
      </article>
    </div>
  </section>
</template>

<script>
export default {
  data: () => ({
    users: []
  }),
  async fetch() {
    this.users = await this.$axios.$get('users')
  },
}
</script>
~
```
- `puravida pages/users/index.vue ~`
```
<template>
  <main class="container">
    <h1>Users</h1>
    <UsersList />
  </main>
</template>
~
```

### User Page
- `puravida pages/users/_id.vue ~`
```
<template>
  <main class="container">
    <h1>{{ user.name }}</h1>
    <section>
      <p>id: {{ user.id }}</p>
      <p>email: {{ user.email }}</p>
      <p>avatar:</p>
      <img :src="user.avatar" />
    </section>
  </main>
</template>

<script>
export default {
  data: () => ({
    user: {},
  }),
  async fetch() {
    this.user = await this.$axios.$get(`users/${this.$route.params.id}`)
  }
}
</script>
~
```

### Nav
- `puravida components/Nav.vue ~`
```
<template>
  <nav class="top-nav container-fluid">
    <ul><li><strong><a href="#">Ruxtmin</a></strong></li></ul>
    <input id="menu-toggle" type="checkbox" />
    <label class='menu-button-container' for="menu-toggle">
      <div class='menu-button'></div>
    </label>
    <ul class="menu">
      <li v-if="!isAuthenticated"><strong><NuxtLink to="/log-in">Log In</NuxtLink></strong></li>
      <li v-if="!isAuthenticated"><strong><NuxtLink to="/sign-up">Sign Up</NuxtLink></strong></li>
      <li v-if="isAdmin"><strong><NuxtLink to="/users">Users</NuxtLink></strong></li>
      <li v-if="isAuthenticated"><strong><a @click="logOut">Log Out</a></strong></li>
    </ul>
  </nav>
</template>

<script>
import { mapGetters } from 'vuex'
export default {
  computed: {
    ...mapGetters(['isAuthenticated', 'isAdmin', 'loggedInUser']),
  }, methods: {
    async logOut() {
      await this.$auth.logout();
    },
  }
}
</script>

<style lang="sass" scoped>
// css-only responsive nav
// from https://codepen.io/alvarotrigo/pen/MWEJEWG (accessed 10/16/23, modified slightly)

h2 
  vertical-align: center
  text-align: center

html, body 
  margin: 0
  height: 100%

.top-nav 
  // display: flex
  // flex-direction: row
  // align-items: center
  // justify-content: space-between
  // background-color: #00BAF0
  // background: linear-gradient(to left, #f46b45, #eea849)
  /* W3C, IE 10+/ Edge, Firefox 16+, Chrome 26+, Opera 12+, Safari 7+ */
  // color: #FFF
  height: 50px
  // padding: 1em

.top-nav > ul 
  margin-top: 15px

.menu 
  display: flex
  flex-direction: row
  list-style-type: none
  margin: 0
  padding: 0

.menu > li 
  // margin: 0 1rem
  overflow: hidden

[type="checkbox"] ~ label.menu-button-container 
  display: none
  height: 100%
  width: 30px
  cursor: pointer
  flex-direction: column
  justify-content: center
  align-items: center

#menu-toggle 
  display: none

.menu-button,
.menu-button::before,
.menu-button::after 
  display: block
  background-color: #000
  position: absolute
  height: 4px
  width: 30px
  transition: transform 400ms cubic-bezier(0.23, 1, 0.32, 1)
  border-radius: 2px

.menu-button::before 
  content: ''
  margin-top: -8px

.menu-button::after 
  content: ''
  margin-top: 8px

#menu-toggle:checked + .menu-button-container .menu-button::before 
  margin-top: 0px
  transform: rotate(405deg)

#menu-toggle:checked + .menu-button-container .menu-button 
  background: rgba(255, 255, 255, 0)

#menu-toggle:checked + .menu-button-container .menu-button::after 
  margin-top: 0px
  transform: rotate(-405deg)

@media (max-width: 991px) 
  [type="checkbox"] ~ label.menu-button-container 
    display: flex

  .top-nav > ul.menu 
    position: absolute
    top: 0
    margin-top: 50px
    left: 0
    flex-direction: column
    width: 100%
    justify-content: center
    align-items: center

  #menu-toggle ~ .menu li 
    height: 0
    margin: 0
    padding: 0
    border: 0
    transition: height 400ms cubic-bezier(0.23, 1, 0.32, 1)

  #menu-toggle:checked ~ .menu li 
    border: 1px solid #333
    height: 2.5em
    padding: 0.5em
    transition: height 400ms cubic-bezier(0.23, 1, 0.32, 1)

  .menu > li 
    display: flex
    justify-content: center
    margin: 0
    padding: 0.5em 0
    width: 100%
    // color: white
    background-color: #222

  .menu > li:not(:last-child) 
    border-bottom: 1px solid #444

</style>
~
```

- `puravida layouts/default.vue ~`
```
<template>
  <div>
    <Nav />
    <Nuxt />
  </div>
</template>
~
```

### Home
- `puravida pages/index.vue ~`
```
<template>
  <main class="container">
    <h1>Rails 7 Nuxt 2 Admin Boilerplate</h1>
    <p>Uses local active storage for user avatars</p>
    <!-- 
    <p>
      <a href="docs/" role="button" class="secondary" aria-label="Documentation">Get started</a> 
      <a href="https://github.com/picocss/pico/archive/refs/tags/v1.5.9.zip" role="button" class="contrast outline" aria-label="Download">Download</a>
    </p>
    <p><code><small>Less than 10 kB minified and gzipped</small></code></p>
    -->
  </main>
</template>
~
```
- `puravida components/Notification.vue ~`
```
<template>
  <div class="notification is-danger">
    {{ message }}
  </div>
</template>

<script>
export default {
  name: 'Notification',
  props: ['message']
}
</script>
~
```
- `puravida pages/log-in.vue ~`
```
<template>
  <section class="bg-white dark:bg-gray-900">
    <div>
      <div>
        <h2>Log In</h2>
        <Notification :message="error" v-if="error"/>
        <form method="post" @submit.prevent="login">
          <div>
            <label>Email</label>
            <div>
              <input
                type="email"
                name="email"
                v-model="email"
              />
            </div>
          </div>
          <div>
            <label>Password</label>
            <div>
              <input
                type="password"
                name="password"
                v-model="password"
              />
            </div>
          </div>
          <div>
            <button type="submit">Log In</button>
          </div>
        </form>
        <div>
          <p>
            Don't have an account? <NuxtLink to="/sign-up">Sign up</NuxtLink>
          </p>
        </div>
        
      </div>
    </div>
  </section>
</template>

<script>
import Notification from '~/components/Notification'
export default {
  auth: false,
  components: {
    Notification,
  },
  data() {
    return {
      email: '',
      password: '',
      error: null
    }
  },
  methods: {
    async login() {
      try {
        await this.$auth.loginWith('local', {
          data: {
            email: this.email,
            password: this.password
          }
        })
        this.$router.push(`/users/${this.$auth.user.id}`)
      } catch (e) {
        this.error = e.response.data.message
      }
    }
  }
}
</script>
~
```
- `puravida pages/sign-up.vue ~`
```
<template>
  <section>
    <div>
      <div>
        <h2>Sign Up</h2>
        <Notification :message="error" v-if="error"/>
        <form method="post" @submit.prevent="register">
          <div>
            <label>Name</label>
            <div>
              <input
                type="name"
                name="name"
                v-model="name"
              />
            </div>
          </div>
          <div>
            <label>Email</label>
            <div>
              <input
                type="email"
                name="email"
                v-model="email"
              />
            </div>
          </div>
          <div>
            <label>Password</label>
            <div>
              <input
                type="password"
                name="password"
                v-model="password"
              />
            </div>
          </div>
          <div>
            <label>Password Confirmation</label>
            <div>
              <input
                type="password"
                name="passwordConfirmation"
                v-model="passwordConfirmation"
              />
            </div>
          </div>
          <div>
            <button type="submit">Log In</button>
          </div>
        </form>        
      </div>
    </div>
  </section>
</template>

<script>
import Notification from '~/components/Notification'
export default {
  auth: false,
  components: {
    Notification,
  },
  data() {
    return {
      name: '',
      email: '',
      password: '',
      passwordConfirmation: '',
      error: null
    }
  },
  methods: {
    async register() {
      try {
        await this.$axios.post('users', {
          "user": {name: this.name,
          email: this.email,
          password: this.password,
          password_confirmation: this.passwordConfirmation}
        })
        await this.$auth.loginWith('local', {
          data: {
          email: this.email,
          password: this.password
          },
        })
        this.$router.push('/')
      } catch (e) {
        this.error = e.response.data.message
      }
    }
  }
}
</script>
~
```
- `puravida store/index.js ~`
```
export const getters = {
  isAuthenticated(state) {
    return state.auth.loggedIn
  },

  isAdmin(state) {
    return state.auth.user?.admin?.toLowerCase() === 'true'
  },

  loggedInUser(state) {
    return state.auth.user
  }
}
```
~
- `npm run dev`
- you can now test the app locally at http://localhost:3001
- kill both the frontend and backend servers by pressing `control + c` in their respective terminal tabs

### DEPLOY TO FLY.IO

### Deploy Backend
- `cd ~/Desktop/back`
- `puravida fly.toml ~`
```
app = "ruxtmin-back"
primary_region = "dfw"
console_command = "/rails/bin/rails console"

[build]

[env]
  RAILS_STORAGE = "/data"

[[mounts]]
  source = "ruxtmin_data"
  destination = "/data"

[http_service]
  internal_port = 3000
  force_https = true
  auto_stop_machines = false
  auto_start_machines = true
  min_machines_running = 0
  processes = ["app"]

[[statics]]
  guest_path = "/rails/public"
  url_prefix = "/"
~
```
- `puravida config/storage.yml ~`
```
test:
  service: Disk
  root: <%= Rails.root.join("tmp/storage") %>

local:
  service: Disk
  root: <%= Rails.root.join("storage") %>

production:
  service: Disk
  root: /data
~
```
- `puravida config/environmnets/production.rb ~`
```
require "active_support/core_ext/integer/time"
Rails.application.configure do
  config.cache_classes = true
  config.eager_load = true
  config.consider_all_requests_local       = false
  config.public_file_server.enabled = ENV["RAILS_SERVE_STATIC_FILES"].present?
  config.active_storage.service = :production
  config.log_level = :info
  config.log_tags = [ :request_id ]
  config.action_mailer.perform_caching = false
  config.i18n.fallbacks = true
  config.active_support.report_deprecations = false
  config.log_formatter = ::Logger::Formatter.new
  if ENV["RAILS_LOG_TO_STDOUT"].present?
    logger           = ActiveSupport::Logger.new(STDOUT)
    logger.formatter = config.log_formatter
    config.logger    = ActiveSupport::TaggedLogging.new(logger)
  end
  config.active_record.dump_schema_after_migration = false
end
~
```
- `fly launch --copy-config --name ruxtmin-back --region dfw --yes`
  - "Would you like to set up a Postgresql database now?": `Yes`
  - "Select configuration: Production (High Availability)": `3 nodes, 4x shared CPUs, 8GB RAM, 80GB disk`
  - wait a bit
  - "Would you like to set up an Upstash Redis database now? (y/N)": `N`
- `fly deploy`
- seed prod users:
  - `fly ssh console`
  - `bin/rails db:seed`
  - `exit`

### Deploy Frontend
- `cd ~/Desktop/front`
- `npm run build`
- `fly launch --name ruxtmin-front --region dfw --yes`
- `fly deploy`

## Sources
- https://suchdevblog.com/tutorials/UploadFilesFromVueToRails.html#our-vue-js-form-component
- https://edgeguides.rubyonrails.org/active_storage_overview.html
- https://stackoverflow.com/questions/76049560/how-to-attach-image-url-in-seed-file-with-rails-active-storage
- https://itecnote.com/tecnote/ruby-on-rails-how-to-get-url-of-the-attachment-stored-in-active-storage-in-the-rails-controller/
- https://stackoverflow.com/questions/50424251/how-can-i-get-url-of-my-attachment-stored-in-active-storage-in-my-rails-controll
- https://stackoverflow.com/questions/5576550/in-rails-how-to-get-current-url-but-no-paths

## Puravida
This readme uses a small custom bash command called [puravida](https://github.com/mark-mcdermott/puravida) - it's just a simple one-liner I wrote to replace `mkdir` and `touch`. Instead of `mkdir folder && touch file.txt`, you can do `puravida folder/file.txt`. It's also a cleaner replacement for multiline text insertion. Instead of doing:
```
mkdir folder
cat >> folder/file.txt << 'END'
first text line
second text line
END
```
you can just do
```
puravida folder/file.txt ~
first text line
second text line
~
```
If you don't feel like downloading my `puravida` script and putting it in your system path, feel free to substitute the instances of `puravida` below with the commands it's replacing.