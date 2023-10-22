<template>
  <main class="container">
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
  </main>
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
          name: this.name,
          email: this.email,
          password: this.password,
          password_confirmation: this.passwordConfirmation
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
