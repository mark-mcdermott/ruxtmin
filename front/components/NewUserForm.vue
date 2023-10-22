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
