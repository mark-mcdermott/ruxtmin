Cypress.Commands.add('login', () => { 
  cy.visit('http://localhost:3001/log-in')
  cy.get('input').eq(1).type('jimhalpert@dundermifflin.com')
  cy.get('input').eq(2).type('password{enter}')
})

Cypress.Commands.add('loginNonAdmin', () => { 
  cy.visit('http://localhost:3001/log-in')
  cy.get('input').eq(1).type('jimhalpert@dundermifflin.com')
  cy.get('input').eq(2).type('password{enter}')
})

Cypress.Commands.add('loginAdmin', () => { 
  cy.visit('http://localhost:3001/log-in')
  cy.get('input').eq(1).type('michaelscott@dundermifflin.com')
  cy.get('input').eq(2).type('password{enter}')
})

Cypress.Commands.add('loginInvalid', () => { 
  cy.visit('http://localhost:3001/log-in')
  cy.get('input').eq(1).type('xyz@dundermifflin.com')
  cy.get('input').eq(2).type('password{enter}')
})

Cypress.Commands.add('logoutNonAdmin', (admin) => { 
  cy.logout(false);
})

Cypress.Commands.add('logoutAdmin', (admin) => { 
  cy.logout(true);
})

Cypress.Commands.add('logout', (admin) => { 
  const num = admin ? 2 : 1
  cy.get('nav ul.menu').find('li').eq(num).click()
    .then(() => { cy.get('nav details ul').find('li').eq(2).click() })
})
