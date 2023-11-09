/// <reference types="cypress" />

// reset the db: rails db:drop db:create db:migrate db:seed RAILS_ENV=test
// run dev server with test db: CYPRESS=1 bin/rails server -p 3000

describe('Non-admin login', () => {
  it('Should go to non-admin show page', () => {
    cy.loginNonAdmin()
    cy.url().should('match', /http:\/\/localhost:3001\/users\/2/)
    cy.get('h2').should('contain', 'Jim Halpert')
    cy.get('p').should('contain', 'id: 2')
    cy.get('p').should('contain', 'avatar:')
    cy.get('p').contains('avatar:').next('img').should('have.attr', 'src').should('match', /http.*jim-halpert.png/)
    cy.get('p').contains('admin').should('not.exist')
    cy.logoutNonAdmin()
  })
  it('Should not contain admin nav', () => {
    cy.loginNonAdmin()
    cy.url().should('match', /http:\/\/localhost:3001\/users\/2/)
    cy.get('nav ul.menu li a').contains('Admin').should('not.exist')
    cy.logoutNonAdmin()
  })
})

describe('Accessing /users as non-admin', () => {
  it('Should redirect to home', () => {
    cy.loginNonAdmin()
    cy.url().should('match', /http:\/\/localhost:3001\/users\/2/)
    cy.visit('http://localhost:3001/users', { failOnStatusCode: false } )
    cy.url().should('match', /^http:\/\/localhost:3001\/$/)
    cy.logoutNonAdmin()
  })
})

describe('Accessing /users/1 as non-admin', () => {
  it('Should go to non-admin show page', () => {
    cy.loginNonAdmin()
    cy.url().should('match', /http:\/\/localhost:3001\/users\/2/)
    cy.visit('http://localhost:3001/users/1', { failOnStatusCode: false } )
    cy.url().should('match', /^http:\/\/localhost:3001\/$/)
    cy.logoutNonAdmin()
  })
})

describe('Accessing /users/2 as non-admin user 2', () => {
  it('Should go to user show page', () => {
    cy.loginNonAdmin()
    cy.url().should('match', /http:\/\/localhost:3001\/users\/2/)
    cy.visit('http://localhost:3001/users/2', { failOnStatusCode: false } )
    cy.url().should('match', /^http:\/\/localhost:3001\/users\/2$/)
    cy.logoutNonAdmin()
  })
})

describe('Accessing /users/3 as non-admin user 2', () => {
  it('Should go to home', () => {
    cy.loginNonAdmin()
    cy.url().should('match', /http:\/\/localhost:3001\/users\/2/)
    cy.visit('http://localhost:3001/users/3', { failOnStatusCode: false } )
    cy.url().should('match', /^http:\/\/localhost:3001\/$/)
    cy.logoutNonAdmin()
  })
})

describe('Accessing /users/1/edit as non-admin', () => {
  it('Should go to non-admin show page', () => {
    cy.loginNonAdmin()
    cy.url().should('match', /http:\/\/localhost:3001\/users\/2/)
    cy.visit('http://localhost:3001/users/1/edit', { failOnStatusCode: false } )
    cy.url().should('match', /^http:\/\/localhost:3001\/$/)
    cy.logoutNonAdmin()
  })
})

describe('Accessing /users/3/edit as non-admin', () => {
  it('Should go to non-admin show page', () => {
    cy.loginNonAdmin()
    cy.url().should('match', /http:\/\/localhost:3001\/users\/2/)
    cy.visit('http://localhost:3001/users/3/edit', { failOnStatusCode: false } )
    cy.url().should('match', /^http:\/\/localhost:3001\/$/)
    cy.logoutNonAdmin()
  })
})

describe('Edit self as non-admin', () => {
  it('Edit should be successful', () => {
    cy.loginNonAdmin()
    cy.url().should('match', /http:\/\/localhost:3001\/users\/2/)
    cy.get('h2').contains('Jim Halpert').next('a').click()
    cy.url().should('match', /http:\/\/localhost:3001\/users\/2\/edit/)
    cy.get('p').contains('Name').next('input').clear()
    cy.get('p').contains('Name').next('input').type('name')
    cy.get('p').contains('Email').next('input').clear()
    cy.get('p').contains('Email').next('input').type('name@mail.com')
    cy.get('input[type=file]').selectFile('cypress/fixtures/images/office-avatars/dwight-schrute.png')
    cy.get('button').click()
    cy.url().should('match', /http:\/\/localhost:3001\/users\/2/)
    cy.get('h2').should('contain', 'name')
    cy.get('p').contains('email').should('contain', 'name@mail.com')
    cy.get('p').contains('avatar:').next('img').should('have.attr', 'src').should('match', /http.*dwight-schrute.png/)
    cy.get('p').contains('admin').should('not.exist')
    cy.get('h2').children().eq(1).click()
    cy.url().should('match', /http:\/\/localhost:3001\/users\/2\/edit/)
    cy.get('p').contains('Name').next('input').clear()
    cy.get('p').contains('Name').next('input').type('Jim Halpert')
    cy.get('p').contains('Email').next('input').clear()
    cy.get('p').contains('Email').next('input').type('jimhalpert@dundermifflin.com')
    cy.get('input[type=file]').selectFile('cypress/fixtures/images/office-avatars/jim-halpert.png')
    cy.get('button').click()
    cy.url().should('match', /http:\/\/localhost:3001\/users\/2/)
    cy.get('h2').should('contain', 'Jim Halpert')
    cy.get('p').contains('email').should('contain', 'jimhalpert@dundermifflin.com')
    cy.get('p').contains('avatar:').next('img').should('have.attr', 'src').should('match', /http.*jim-halpert.png/)
    cy.get('p').contains('admin').should('not.exist')
    cy.logoutNonAdmin()
  })
})
