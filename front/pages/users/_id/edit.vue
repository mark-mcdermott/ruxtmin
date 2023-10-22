<template>
  <main class="container">
    <section>
      <article>
        <h2>Edit User</h2>
        <p>id: {{ user.id }}</p>
        <form enctype="multipart/form-data">
          <p>Name: </p><input v-model="user.name">
          <p>Email: </p><input v-model="user.email">
          <p>Avatar: </p>
          <img :src="user.avatar" />
          <input type="file" ref="inputFile" @change=uploadAvatar()>
          <button @click.prevent=editUser>Edit User</button>
        </form>
      </article>
    </section>
  </main>
</template>

<script>
export default {
  data: () => ({
    user: {},
    avatar: null
  }),
  async fetch() {
    this.user = await this.$axios.$get(`users/${this.$route.params.id}`)
  },
  methods: {
    uploadAvatar: function() {
      this.avatar = this.$refs.inputFile.files[0];
    },
    editUser: function() {
      let params = {}
      if (this.avatar == null) {
        params = {'name': this.user.name,'email': this.user.email}
      } else {
        params = {'name': this.user.name,'email': this.user.email,'avatar': this.avatar}
      }
      let payload = new FormData()
      Object.entries(params).forEach(
        ([key, value]) => payload.append(key, value)
      )
      this.$axios.$patch(`/users/${this.$route.params.id}`, payload)
      this.$router.push(`/users/${this.$route.params.id}`)
    }
  }
}
</script>
