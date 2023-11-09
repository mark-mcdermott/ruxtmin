let development = process.env.NODE_ENV !== 'production'
export default {
  ssr: false,
  head: { title: 'front', htmlAttrs: { lang: 'en' },
    meta: [ { charset: 'utf-8' },
      { name: 'viewport', content: 'width=device-width, initial-scale=1' },
      { hid: 'description', name: 'description', content: '' },
      { name: 'format-detection', content: 'telephone=no' }
    ], link: [{ rel: 'icon', type: 'image/x-icon', href: '/favicon.ico' }]
  },
  css: ['@fortawesome/fontawesome-svg-core/styles.css','@/assets/scss/main.scss'],
  plugins: [ '~/plugins/fontawesome.js' ],
  components: true,
  buildModules: [],
  router: { middleware: ['auth'] },
  modules: ['@nuxtjs/axios', '@nuxtjs/auth'],
  axios: { baseURL: development ? 'http://localhost:3000' : 'https://ruxtmin-back.fly.dev/' },
  server: { port: development ? 3001 : 3000 },
  auth: {
    redirect: { login: '/' },
    strategies: {
      local: {
        endpoints: {
          login: { url: 'login', method: 'post', propertyName: 'data' },
          logout: false,
          user: { url: 'me', method: 'get', propertyName: 'data' }
        }
      }
    }
  }
}
