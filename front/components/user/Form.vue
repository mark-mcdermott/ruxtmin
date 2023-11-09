<template>
  <section>
    <h1 v-if="editNewOrSignup === 'edit'">Edit User</h1>
    <h1 v-else-if="editNewOrSignup === 'new'">Add User</h1>
    <h1 v-else-if="editNewOrSignup === 'sign-up'">Sign Up</h1>
    <article>
      <form enctype="multipart/form-data">
        <p v-if="editNewOrSignup === 'edit'">id: {{ $route.params.id }}</p>
        <p>Name: </p><input v-model="name">
        <p>Email: </p><input v-model="email">
        <p class="no-margin">Avatar: </p>
        <img v-if="!hideAvatar && editNewOrSignup === 'edit'" :src="avatar" />    
        <input type="file" ref="inputFile" @change=uploadAvatar()>
        <p v-if="editNewOrSignup !== 'edit'">Password: </p>
        <input v-if="editNewOrSignup !== 'edit'" type="password" v-model="password">
        <button v-if="editNewOrSignup !== 'edit'" @click.prevent=createUser>Create User</button>
        <button v-else-if="editNewOrSignup == 'edit'" @click.prevent=editUser>Edit User</button>
      </form>
    </article>
  </section>
</template>

<script>
import { mapGetters } from 'vuex'
export default {
  data () {
    return {
      name: "",
      email: "",
      avatar: "",
      password: "",
      editNewOrSignup: "",
      hideAvatar: false
    }
  },
  mounted() {
    const splitPath = $nuxt.$route.path.split('/')
    this.editNewOrSignup = splitPath[splitPath.length-1]
  },
  computed: {
    ...mapGetters(['isAuthenticated', 'isAdmin', 'loggedInUser`']),
  },
  async fetch() {
    const splitPath = $nuxt.$route.path.split('/')
    this.editNewOrSignup = $nuxt.$route.path.split('/')[$nuxt.$route.path.split('/').length-1]
    if ($nuxt.$route.path.split('/')[$nuxt.$route.path.split('/').length-1]=='edit') {
      const user = await this.$axios.$get(`users/${this.$route.params.id}`)
      this.name = user.name
      this.email = user.email,
      this.avatar = user.avatar  
    }
  },
  methods: {
    uploadAvatar: function() {
      this.avatar = this.$refs.inputFile.files[0]
      this.hideAvatar = true
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
        .then(() => {
          this.$auth.loginWith('local', {
            data: {
            email: this.email,
            password: this.password
            },
          })
          .then(() => {
            const userId = this.$auth.$state.user.id
            this.$router.push(`/users/${userId}`)
          })
        })
    },
    editUser: function() {
      let params = {}
      const filePickerFile = this.$refs.inputFile.files[0]
      if (!filePickerFile) {
        params = { 'name': this.name, 'email': this.email }
      } else {
        params = { 'name': this.name, 'email': this.email, 'avatar': this.avatar }
      }
    
      let payload = new FormData()
      Object.entries(params).forEach(
        ([key, value]) => payload.append(key, value)
      )
      this.$axios.$patch(`/users/${this.$route.params.id}`, payload)
        .then(() => {
          this.$router.push(`/users/${this.$route.params.id}`)
        })
    },
  }
}
</script>
