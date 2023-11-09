<template>
  <main class="container">
    <UserForm />
  </main>
</template>

<script>
export default { middleware: 'currentUserOrAdminOnly' }
</script>
