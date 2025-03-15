describe('Sign Up Tests', () => {
    it('should allow a user to sign up with valid data', () => {
      cy.visit('/sign_up'); // Visit the sign-up page
      
      // Fill in the form with valid data
      cy.get('input[name="username"]').type('newuser1');
      cy.get('input[name="user_email"]').type('newuser1@example.com');
      cy.get('input[name="password"]').type('password123');
      cy.get('input[name="confirm_password"]').type('password123');
      
      // Submit the form
      cy.get('form').submit();
      
      // Check that the user is redirected to the homepage after sign-up
      cy.url().should('eq', Cypress.config().baseUrl + '/products');
    });
  
    it('should show an error if passwords do not match', () => {
      cy.visit('/sign_up');
      
      cy.get('input[name="username"]').type('newuser2');
      cy.get('input[name="user_email"]').type('newuser2@example.com');
      cy.get('input[name="password"]').type('password123');
      cy.get('input[name="confirm_password"]').type('differentpassword');
      
      cy.get('form').submit();
      
      cy.contains('Passwords do not match').should('be.visible');
    });
  
    it('should show an error if username or email is already in use', () => {
      cy.visit('/sign_up');
      
      // Use an existing username or email (replace with a known one in your DB)
      cy.get('input[name="username"]').type('newuser1');
      cy.get('input[name="user_email"]').type('newuser1@example.com');
      cy.get('input[name="password"]').type('password123');
      cy.get('input[name="confirm_password"]').type('password123');
      
      cy.get('form').submit();
      
      cy.contains('Username or email already in use').should('be.visible');
    });
  
    it('should block sign up after too many attempts in a short period', () => {
      cy.visit('/sign_up');
      
      // Simulate failed attempts (assuming you have a way to control the number of failed attempts in the backend)
      cy.get('input[name="username"]').type('testuser');
      cy.get('input[name="user_email"]').type('testuser@example.com');
      cy.get('input[name="password"]').type('password123');
      cy.get('input[name="confirm_password"]').type('password123');
      cy.get('form').submit();
      
      // After a few failed attempts, the system should block the user
      cy.contains('Too many attempts. Try again later.').should('be.visible');
    });
  });
  