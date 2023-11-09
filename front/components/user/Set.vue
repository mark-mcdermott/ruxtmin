<template>
  <section>
    <div v-for="user in users" :key="user.id">
      <UserCard :user="user" :users="users" />
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
  }
}
</script>
