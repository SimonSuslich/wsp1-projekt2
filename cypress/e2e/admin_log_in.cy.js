describe('Admin Log In Tests', () => {
    it('should allow an admin to log in with valid credentials', () => {
        cy.visit('/admin/log_in'); // Visit the admin login page

        // Fill in the form with valid admin credentials
        cy.get('input[name="name_email"]').type('admin');
        cy.get('input[name="password"]').type('admin');

        // Submit the form
        cy.get('form').submit();

        // Check that the admin is redirected to the admin dashboard
        cy.url().should('eq', Cypress.config().baseUrl + '/admin/dashboard');
    });

    it('should show an error for invalid admin credentials', () => {
        cy.visit('/admin/log_in');

        cy.get('input[name="name_email"]').type('wrongadmin@example.com');
        cy.get('input[name="password"]').type('wrongpassword');

        cy.get('form').submit();

        cy.contains('Invalid credentials').should('be.visible');
    });

    it('should show an error for invalid admin credentials', () => {
        cy.visit('/admin/log_in');

        cy.get('input[name="name_email"]').type('admin');
        cy.get('input[name="password"]').type('wrongpassword');

        cy.get('form').submit();

        cy.contains('Invalid credentials').should('be.visible');
    });

    it('should block admin login after too many failed attempts', () => {
        cy.visit('/admin/log_in');

        // Simulate failed admin login attempts
        cy.get('input[name="name_email"]').type('admin');
        cy.get('input[name="password"]').type('wrongpassword');
        cy.get('form').submit();

        // After multiple failed attempts, the user should be blocked
        cy.contains('Too many attempts. Try again later.').should('be.visible');
    });
});
