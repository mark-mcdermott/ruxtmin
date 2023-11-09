import { mapGetters } from 'vuex'
export default function ({ route, store, redirect }) {
  const { isAdmin, loggedInUser } = store.getters
  const url = route.fullPath;
  const splitPath = url.split('/')
  let idParam = null;
  if (url.includes("edit")) {
    idParam = parseInt(splitPath[splitPath.length-2])
  } else {
    idParam = parseInt(splitPath[splitPath.length-1])
  }
  const isUserCurrentUser = idParam === loggedInUser.id
  if (!isAdmin && !isUserCurrentUser) {
    return redirect('/')
  }
}
