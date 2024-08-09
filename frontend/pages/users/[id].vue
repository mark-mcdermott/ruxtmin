<script setup>
definePageMeta({ auth: false })

const route = useRoute()
const user = ref({})
const avatar = ref(null)

async function fetchUser() {
  const { apiBase } = useRuntimeConfig().public
  const response = await fetch(`${apiBase}/users/${route.params.id}`)
  user.value = await response.json()

  console.log('Fetched user avatar URL:', user.value.avatar_url)
}

async function saveUserChanges(updatedUser) {
  const { apiBase } = useRuntimeConfig().public
  const formData = new FormData()
  formData.append('user[email]', updatedUser.email)
  formData.append('user[uuid]', updatedUser.uuid)
  if (avatar.value) {
    formData.append('user[avatar]', avatar.value)
  }

  await fetch(`${apiBase}/users/${route.params.id}`, {
    method: 'PATCH',
    body: formData,
  })

  // Wait a moment before fetching updated user data
  setTimeout(fetchUser, 500)
}

async function deleteUser() {
  const { apiBase } = useRuntimeConfig().public
  await fetch(`${apiBase}/users/${route.params.id}`, {
    method: 'DELETE',
  })
  navigateTo('/users')
}

function onFileChange(e) {
  avatar.value = e.target.files[0]
  console.log('Selected file:', avatar.value)
}

// Watch for changes in the email field and avatar value
watch(
  () => user.value.email,
  (newEmail, oldEmail) => {
    if (newEmail !== oldEmail) {
      saveUserChanges(user.value)
    }
  },
)

watch(
  avatar,
  (newAvatar, oldAvatar) => {
    if (newAvatar !== oldAvatar) {
      saveUserChanges(user.value)
    }
  },
)

onMounted(fetchUser)
</script>

<template>
  <UiContainer class="relative flex flex-col py-10 lg:py-20">
    <div
      class="absolute inset-0 z-[-2] h-full w-full bg-transparent bg-[linear-gradient(to_right,_theme(colors.border)_1px,_transparent_1px),linear-gradient(to_bottom,_theme(colors.border)_1px,_transparent_1px)] bg-[size:80px_80px] [mask-image:radial-gradient(#000,_transparent_80%)]"
    />
    <div class="flex h-full lg:w-[768px]">
      <div>
        <h1 class="mb-4 text-4xl font-bold md:text-5xl lg:mb-6 lg:mt-5 xl:text-6xl">
          User
        </h1>
        <div class="flex items-center justify-center">
          <form @submit.prevent="saveUserChanges(user)">
            <UiCard class="w-[360px] max-w-sm" :title="user.email">
              <template #content>
                <UiCardContent>
                  <div class="grid w-full items-center gap-4">
                    <div class="flex flex-col space-y-1.5">
                      <UiLabel for="email">
                        Email
                      </UiLabel>
                      <UiInput id="email" v-model="user.email" required />
                    </div>
                    <div class="flex flex-col space-y-1.5">
                      <UiLabel for="uuid">
                        UUID
                      </UiLabel>
                      <p class="text-sm">
                        {{ user.uuid }}
                      </p>
                    </div>
                    <div class="flex flex-col space-y-1.5">
                      <UiLabel for="avatar">
                        Avatar
                      </UiLabel>
                      <div v-if="user.avatar_url">
                        <img :src="`${user.avatar_url}?${new Date().getTime()}`" alt="User Avatar" class="w-32 h-32 object-cover rounded-full">
                      </div>
                      <input type="file" @change="onFileChange">
                    </div>
                  </div>
                </UiCardContent>
              </template>
              <template #footer>
                <UiCardFooter class="flex justify-between">
                  <UiButton variant="destructive" @click.prevent="deleteUser">
                    <Icon name="lucide:trash" />
                    Delete User
                  </UiButton>
                </UiCardFooter>
              </template>
            </UiCard>
          </form>
        </div>
      </div>
    </div>
  </UiContainer>
</template>