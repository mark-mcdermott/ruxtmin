<template>
  <main class="container">
    <h1>Rails 7 Nuxt 2 Admin Boilerplate</h1>
    
    <h2 class="small-bottom-margin">Features</h2>
    <ul class="features">
      <li>Admin dashboard</li>
      <li>Placeholder users</li>
      <li>Placeholder user item ("widget")</li>
    </ul>

    <h3 class="small-bottom-margin stack">Stack</h3>
    <div class="aligned-columns">
      <p><span>frontend:</span> Nuxt 2</p>
      <p><span>backend API:</span> Rails 7</p>
      <p><span>database:</span> Postgres</p>
      <p><span>styles:</span> Sass</p>
      <p><span>css framework:</span> Pico.css</p>
      <p><span>frontend tests:</span> Jest</p>
      <p><span>backend tests:</span> RSpec</p>
    </div>

    <h3 class="small-bottom-margin tools">Tools</h3>
    <div class="aligned-columns">
      <p><span>user avatars:</span> local active storage</p>
      <p><span>backend auth:</span> bcrypt & jwt</p>
      <p><span>frontend auth:</span> nuxt auth module</p>
    </div>

    <h3 class="small-bottom-margin">User Logins</h3>
    <table class="half-width">
      <tr><th>Email</th><th>Password</th><th>Notes</th></tr>
      <tr><td>michaelscott@dundermifflin.com</td><td>password</td><td>(admin)</td></tr>
      <tr><td>jimhalpert@dundermifflin.com</td><td>password</td><td></td></tr>
      <tr><td>pambeesly@dundermifflin.com</td><td>password</td><td></td></tr>
    </table>
    
    <p class="big-bottom-margin">
      <NuxtLink to="/log-in" role="button" class="secondary">Log In</NuxtLink> 
      <NuxtLink to="/sign-up" role="button" class="contrast outline">Sign Up</NuxtLink>
    </p>    

  </main>
</template>

<script>
export default { auth: false }
</script>
