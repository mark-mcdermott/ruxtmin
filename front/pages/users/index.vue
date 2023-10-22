<template>
  <main class="container">
    <h1>Users</h1>
    <UserCards />
  </main>
</template>

<script>
export default {
  middleware: 'adminOnly'
}
</script>
