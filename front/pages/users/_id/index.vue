<template>
  <main class="container">
    <section>
      <UserCard :user="user" />
    </section>
  </main>
</template>

<script>
export default {
  middleware: 'currentUserOrAdminOnly',
  data: () => ({ user: {} }),
  async fetch() { this.user = await this.$axios.$get(`users/${this.$route.params.id}`) },
  methods: {
    uploadAvatar: function() { this.avatar = this.$refs.inputFile.files[0] },
    deleteUser: function(id) {
      this.$axios.$delete(`users/${this.$route.params.id}`)
      this.$router.push('/users')
    }
  }
}
</script>
