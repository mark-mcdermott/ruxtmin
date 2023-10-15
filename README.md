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
- `rails g model user name email avatar:attachment admin:boolean password_digest`
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
    @user = User.find(param[:id])
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
  buildModules: [
  ],
  modules: [
    '@nuxtjs/axios',
  ],
  axios: {
    baseURL: development ? 'http://localhost:3000' : 'https://back-v001.fly.dev/'
  },
}
~
```
- `rm -rf components/*`
- `y`
- `puravida components/FileUpload.vue ~`
```
<template>
  <div>
    <header>&nbsp;</header>
    <main class="container">
      <section>
        <h2>Add an user</h2>
        <form enctype="multipart/form-data">
          <p>Name: </p><input v-model="inputName">
          <p>Email :</p><input v-model="inputDescription">
          <p>Avatar :</p><input type="file" ref="inputFile" @change=uploadFile()>
          <p>Password :</p><input type="password" v-model="inputPassword">
          <button @click.prevent=createUser>Create this User !</button>
        </form>
      </section>
    </main>
  </div>
</template>

<script>
export default {
  name: 'usersForm',
  data () {
    return {
      inputName: "",
      inputDescription: "",
      inputAvatar: null,
      inputPassword: ""
    }
  },
  methods: {
    uploadFile: function() {
      this.inputAvatar = this.$refs.inputFile.files[0];
    },
    createUser: function() {
      const params = {
        'name': this.inputName,
        'email': this.inputDescription,
        'avatar': this.inputAvatar,
        'password': this.inputPassword,
      }
      let formData = new FormData()
      Object.entries(params).forEach(
        ([key, value]) => formData.append(key, value)
      )
      this.$axios.$post('users', formData)
    }
  }
}
</script>
~
```
- `puravida components/Home.vue ~`
```
<template>
  <div>
    <header>&nbsp;</header>
    <main class="container">
      <section>
        <h2>Users</h2>
        <div v-for="user in users" :key="user.id">
          <p>Name: {{ user.name }}</p>
          <p>Email: {{ user.email }}</p>
          <p>Avatar:</p>
          <img :src="user.avatar" />
          <p>Admin: {{ user.admin }}</p>
        </div>
      </section>
    </main>
  </div>
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
- `puravida pages/new.vue ~`
```
<template>
  <FileUpload />
</template>
~
```
- `puravida pages/index.vue ~`
```
<template>
  <Home />
</template>

<script>
export default {
  name: 'IndexPage'
}
</script>
~
```
- `npm run dev`
