describe('Log In Tests', () => {
    it('should allow a user to log in with valid credentials', () => {
      cy.visit('/log_in'); // Visit the login page
  
      // Fill in the form with valid credentials
      cy.get('input[name="user_name_email"]').type('newuser1@example.com');
      cy.get('input[name="password"]').type('password123');
      
      // Submit the form
      cy.get('form').submit();
      
      // Check that the user is redirected to the homepage after logging in
      cy.url().should('eq', Cypress.config().baseUrl + '/products');
    });
  
    it('should show an error for invalid credentials', () => {
      cy.visit('/log_in');
      
      cy.get('input[name="user_name_email"]').type('nonexistentuser@example.com');
      cy.get('input[name="password"]').type('wrongpassword');
      
      cy.get('form').submit();
      
      cy.contains('Invalid credentials').should('be.visible');
    });

    it('should show an error for invalid credentials', () => {
      cy.visit('/log_in');
      
      cy.get('input[name="user_name_email"]').type('newuser1@example.com');
      cy.get('input[name="password"]').type('wrongpassword');
      
      cy.get('form').submit();
      
      cy.contains('Invalid credentials').should('be.visible');
    });
  
    it('should block login after too many failed attempts', () => {
      cy.visit('/log_in');
      
      // Simulate failed login attempts
      cy.get('input[name="user_name_email"]').type('newuser1@example.com');
      cy.get('input[name="password"]').type('wrongpassword');
      cy.get('form').submit();
      
      // After multiple failed attempts, the user should be blocked
      cy.contains('Too many attempts. Try again later.').should('be.visible');
    });
  });
  