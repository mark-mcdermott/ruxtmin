<template>
  <article>
    <h2>
      <NuxtLink :to="`/users/${user.id}`">{{ user.name }}</NuxtLink> 
      <NuxtLink :to="`/users/${user.id}/edit`"><font-awesome-icon icon="pencil" /></NuxtLink>
      <a @click.prevent=deleteUser(user.id) href="#"><font-awesome-icon icon="trash" /></a>
    </h2>
    <p>id: {{ user.id }}</p>
    <p>email: {{ user.email }}</p>
    <p v-if="user.avatar !== null" class="no-margin">avatar:</p>
    <img v-if="user.avatar !== null" :src="user.avatar" />
    <p v-if="isAdmin">admin: {{ user.admin }}</p>
  </article>
</template>

<script>
import { mapGetters } from 'vuex'
export default {
  name: 'UserCard',
  computed: { ...mapGetters(['isAdmin']) },
  props: {
    user: {
      type: Object,
      default: () => ({}),
    },
    users: {
      type: Array,
      default: () => ([]),
    },
  },
  methods: {
    uploadAvatar: function() {
      this.avatar = this.$refs.inputFile.files[0];
    },
    deleteUser: function(id) {
      this.$axios.$delete(`users/${id}`)
      const index = this.users.findIndex((i) => { return i.id === id })
      this.users.splice(index, 1);
    }
  }
}
</script>
