# Rails 7 Nuxt 2 Admin Boilerplate (With Active Storage Avatars)

This uses Nuxt 2 as a frontend and Rails 7 as a backend API and uses very simple implementation of Rail's Active Storage for local file upload and image display.

## Sources
- https://suchdevblog.com/tutorials/UploadFilesFromVueToRails.html#our-vue-js-form-component
- https://edgeguides.rubyonrails.org/active_storage_overview.html

## BACKEND
- `cd ~/Desktop`
- `rails new back --api --database=postgresql`
- `cd back`
- create database
  - if first time doing this: `rails db:create`
  - if database already exists: `rails db:drop db:create`
- `bundle add rack-cors bcrypt`
- `rails active_storage:install`
- `rails db:migrate`

### Health Controller
- `rails g controller health index`
- `puravida app/controllers/health_controller.rb ~`
```
class HealthController < ApplicationController
  def index
    render json: { status: 'online', status: 200 }
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
      t.string :name
      t.string :email, null: false, index: { unique: true }
      t.boolean :admin, default: false
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
    {
      name: admin_params[:name],
      email: admin_params[:email],
      admin: admin_params[:admin],
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
user.avatar.attach(io: URI.open("/Users/mmcdermott/Desktop/back/app/assets/office-avatars/michael-scott.png"), filename: "michael-scott.png")
user.save!
user = User.create(name: "Jim Halpert", email: "jimhalpert@dundermifflin.com", admin: "false", password: "password")
user.avatar.attach(io: URI.open("/Users/mmcdermott/Desktop/back/app/assets/office-avatars/jim-halpert.png"), filename: "jim-halpert.png")
user.save!
user = User.create(name: "Pam Beesly", email: "pambeesly@dundermifflin.com", admin: "false", password: "password")
user.avatar.attach(io: URI.open("/Users/mmcdermott/Desktop/back/app/assets/office-avatars/pam-beesly.png"), filename: "jim-halpert.png")
user.save!
~
```
- `rails db:seed`
- `rails s`

## FRONTEND

### Setup
- (in a separate terminal tab)
- `cd ~/Desktop`
- `npx create-nuxt-app front`
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
- `puravida nuxt.config.js ~`
```
let development = process.env.NODE_ENV !== 'production'
export default {
  ssr: false,
  head: {
    title: 'front-test',
    htmlAttrs: {
      lang: 'en'
    },
    meta: [
      { charset: 'utf-8' },
      { name: 'viewport', content: 'width=device-width, initial-scale=1' },
      { hid: 'description', name: 'description', content: '' },
      { name: 'format-detection', content: 'telephone=no' }
    ],
    link: [
      { rel: 'icon', type: 'image/x-icon', href: '/favicon.ico' },
      { rel: 'stylesheet', href: 'https://cdn.jsdelivr.net/npm/@picocss/pico@1/css/pico.min.css' }
    ]
  },
  components: true,
  buildModules: [],
  modules: ['@nuxtjs/axios'],
  axios: { baseURL: development ? 'http://localhost:3000' : 'https://back-v001.fly.dev/' },
  server: { port: 3001 }
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
      <p>Email :</p><input v-model="email">
      <p>Avatar :</p><input type="file" ref="inputFile" @change=uploadAvatar()>
      <p>Password :</p><input type="password" v-model="password">
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
    <h1>User</h1>
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
    <header><h1>{{ user.name }}</h1></header>
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
  <nav class="container-fluid">
    <ul><li><strong><NuxtLink to="/">Ruxtmin</NuxtLink></strong></li></ul>
    <ul>
      <li><strong><NuxtLink to="/users">Users</NuxtLink></strong></li>
      <li><strong><NuxtLink to="/users/new">New User</NuxtLink></strong></li>
      <!-- <li><a class="seconday" href="#" role="button">Button</a></li> -->
    </ul>
  </nav>
</template>
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
- `npm run dev`
