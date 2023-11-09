/// <reference types="cypress" />

// reset the db: db:drop db:create db:migrate db:seed RAILS_ENV=test
// run dev server with test db: CYPRESS=1 bin/rails server -p 3000

describe('Manual Login', () => {
  it('Should log in user', () => {
    cy.intercept('POST', '/login').as('login')
    cy.loginAdmin()
    cy.wait('@login').then(({response}) => {
      expect(response.statusCode).to.eq(200)
    })
    cy.url().should('eq', 'http://localhost:3001/users/1')
    cy.get('h2').should('contain', 'Michael Scott')
    cy.logoutAdmin()
  })
})

context('Mocked Request Login', () => {
  describe('Login with real email', () => {
    it('Should get 200 response', () => {
      cy.visit('http://localhost:3001/log-in')
      cy.request(
        { url: 'http://localhost:3000/login', method: 'POST', body: { email: 'michaelscott@dundermifflin.com', 
        password: 'password' }, failOnStatusCode: false })
        .its('status').should('equal', 200)
      cy.get('h2').should('contain', 'Log In')
      cy.url().should('include', '/log-in')
    })
  })

  describe('Login with fake email', () => {
    it('Should get 401 response', () => {
      cy.visit('http://localhost:3001/log-in')
      cy.request(
        { url: 'http://localhost:3000/login', method: 'POST', body: { email: 'xyz@dundermifflin.com', 
        password: 'password' }, failOnStatusCode: false })
        .its('status').should('equal', 401)
      cy.get('h2').should('contain', 'Log In')
      cy.url().should('include', '/log-in')
    })
  })
})
