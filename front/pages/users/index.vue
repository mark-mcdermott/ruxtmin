<template>
  <main class="container">
    <h1>Users</h1>
    <NuxtLink to="/users/new" role="button">Add User</NuxtLink>
    <UserSet />
  </main>
</template>

<script>
export default { middleware: 'adminOnly' }
</script>
