export default function ({ route, store, redirect }) {
  const splitPath = route.fullPath.split('/')
  const idParam = splitPath[splitPath.length-1]
  const currentUserId = store.state.auth.user.id
  const isAdmin = store.state.auth.user.admin
  if (!isAdmin && idParam != currentUserId) {
    return redirect('/')
  }
}
