/// <reference types="cypress" />

// reset the db: db:drop db:create db:migrate db:seed RAILS_ENV=test
// run dev server with test db: CYPRESS=1 bin/rails server -p 3000
context('Logged Out', () => {
  describe('Homepage Copy', () => {
    it('should find page copy', () => {
      cy.visit('http://localhost:3001/')
      cy.get('main.container')
        .should('contain', 'Rails 7 Nuxt 2 Admin Boilerplate')
        .should('contain', 'Features')
      cy.get('ul.features')
        .within(() => {
          cy.get('li').eq(0).contains('Admin dashboard')
          cy.get('li').eq(1).contains('Placeholder users')
          cy.get('li').eq(2).contains('Placeholder user item ("widget")')
        })
      cy.get('h3.stack')
        .next('div.aligned-columns')
          .within(() => {
            cy.get('p').eq(0).contains('frontend:')
            cy.get('p').eq(0).contains('Nuxt 2')
            cy.get('p').eq(1).contains('backend API:')
            cy.get('p').eq(1).contains('Rails 7')
            cy.get('p').eq(2).contains('database:')
            cy.get('p').eq(2).contains('Postgres')
            cy.get('p').eq(3).contains('styles:')
            cy.get('p').eq(3).contains('Sass')
            cy.get('p').eq(4).contains('css framework:')
            cy.get('p').eq(4).contains('Pico.css')
            cy.get('p').eq(5).contains('frontend tests:')
            cy.get('p').eq(5).contains('Jest')
            cy.get('p').eq(6).contains('backend tests:')
            cy.get('p').eq(6).contains('RSpec')      
          })
      cy.get('h3.tools')
        .next('div.aligned-columns')
          .within(() => {
            cy.get('p').eq(0).contains('user avatars:')
            cy.get('p').eq(0).contains('local active storage')
            cy.get('p').eq(1).contains('backend auth:')
            cy.get('p').eq(1).contains('bcrypt & jwt')
            cy.get('p').eq(2).contains('frontend auth:')
            cy.get('p').eq(2).contains('nuxt auth module')
          }) 
    })
  })

  describe('Log In Copy', () => {
    it('should find page copy', () => {
      cy.visit('http://localhost:3001/log-in')
      cy.get('main.container')
        .should('contain', 'Email')
        .should('contain', 'Password')
        .should('contain', 'Log In')
        .should('contain', "Don't have an account")
    })
  })

  describe('Sign Up Copy', () => {
    it('should find page copy', () => {
      cy.visit('http://localhost:3001/sign-up')
      cy.get('main.container')
        .should('contain', 'Name')
        .should('contain', 'Email')
        .should('contain', 'Avatar')
        .should('contain', 'Password')
        .should('contain', 'Create User')
    })
  })
})
