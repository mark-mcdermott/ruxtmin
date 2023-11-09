<template>
  <main class="container">
    <h1>Widgets</h1>
    <NuxtLink to="/users/new" role="button">Add Widgets</NuxtLink>
    <WidgetSet />
  </main>
</template>

<script>
export default {
  middleware: 'adminOnly'
}
</script>
