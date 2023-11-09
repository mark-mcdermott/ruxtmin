<template>
  <main class="container">
    <h1>Admin</h1>
    <p>Number of users: {{ this.users.length }}</p>
    <p>Number of admins: {{ (this.users.filter((obj) => obj.admin === true)).length }}</p>
    <p><NuxtLink to="/users">Users</NuxtLink></p>
    <p><NuxtLink to="/admin/widgets">Widgets</NuxtLink></p>
  </main>
</template>

<script>
export default { 
  middleware: 'adminOnly',
  layout: 'admin',
  data: () => ({ users: [] }),
  async fetch() { this.users = await this.$axios.$get('users') }
}
</script>
