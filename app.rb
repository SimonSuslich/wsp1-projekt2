require 'securerandom'
require 'sinatra'
require 'fileutils'
require 'time'
require_relative 'lib/product_helpers'
require_relative 'lib/user_helpers'
require_relative 'lib/admin_helpers'
require_relative 'lib/cart_helpers'


##
# This is the main application class handling routes for users, admins, products, and the shopping cart.
# It also includes session management and authentication.
#
class App < Sinatra::Base

    # @return [SQLite3::Database] Returns the database connection.
    def db
        return @db if @db

        @db = SQLite3::Database.new("db/vcars.sqlite")
        @db.results_as_hash = true

        return @db
    end

    # Configures session settings, enabling sessions with a secret key.
    configure do
        enable :sessions
        set :session_secret, SecureRandom.hex(64)
    end

    ##
    # @method GET / 
    # @route GET / 
    # Redirects the root URL ("/") to the products page.
    #
    # @return [void]
    get '/' do
        redirect("/products")
    end

    ##
    # @method GET /about
    # @route GET /about
    # Renders the "About" page.
    #
    # @return [void]
    get '/about' do 
        erb(:"about")
    end

    # ADMIN CRUD

    # Before every admin route, checks if the user is authenticated.
    before '/admin/*' do
        pass if request.path_info == '/admin/log_in'
        authenticate_admin()
    end

    ##
    # @method GET /admin/log_in
    # @route GET /admin/log_in
    # Displays the admin login page.
    #
    # @return [void]
    get '/admin/log_in' do 
        erb(:"admin/log_in")
    end

    ##
    # @method POST /admin/log_in
    # @route POST /admin/log_in
    # Handles admin login attempts, enforcing rate limits and session management.
    #
    # @return [void]
    # @example Successful login
    #   POST /admin/log_in
    #
    # @example Failed login (too many attempts)
    #   POST /admin/log_in -> 429 Too many attempts
    #
    FAILED_ATTEMPTS ||= {}  
    post '/admin/log_in' do
        ip = request.ip
        FAILED_ATTEMPTS[ip] ||= { count: 0, last_attempt: nil }

        # Reset failed attempts after 24 hours
        if FAILED_ATTEMPTS[ip][:last_attempt] && Time.now - FAILED_ATTEMPTS[ip][:last_attempt] > 24*3600
            FAILED_ATTEMPTS[ip] = { count: 0, last_attempt: nil }
        end

        # Enforce rate limit for login attempts (max 3 within 1 minute)
        if FAILED_ATTEMPTS[ip][:count] >= 3
            if FAILED_ATTEMPTS[ip][:last_attempt] && Time.now - FAILED_ATTEMPTS[ip][:last_attempt] < 60
                halt erb(:error, locals: { message: "Too many attempts. Try again later.", status: 429, route: "/admin/log_in" })
            end
        end

        admin_name_email = params['name_email']
        cleartext_password = params['password'] 

        admin = get_admin(admin_name_email)

        password_from_db = BCrypt::Password.new(admin['password'])

        # Check if password matches
        if password_from_db == cleartext_password
            session[:admin_id] = admin['id']
            FAILED_ATTEMPTS[ip] = { count: 0, last_attempt: nil }
            redirect '/admin/dashboard'
        else
            FAILED_ATTEMPTS[ip][:count] += 1
            p "count increased"
            FAILED_ATTEMPTS[ip][:last_attempt] = Time.now
            halt erb(:error, locals: { message: "Invalid credentials", status: 401, route: "/admin/log_in" })
        end
    end

    ##
    # @method GET /admin/dashboard
    # @route GET /admin/dashboard
    # Renders the admin dashboard page.
    #
    # @return [void]
    get '/admin/dashboard' do
        erb(:"admin/dashboard")
    end

    ##
    # @method GET /admin/products
    # @route GET /admin/products
    # Renders the product listing page for the admin panel.
    #
    # @return [void]
    get '/admin/products' do 
        @all_products = admin_view_products()

        @all_products.each do |product|
            product[:formated_price] = pretty_print_price(product["price"])
        end

        erb(:"admin/products")
    end

    ##
    # @method GET /products
    # @route GET /products
    # Renders the product listing page for regular users.
    #
    # @return [void]
    get '/products' do
        @all_products = select_products_and_combine_images()

        @all_products.each do |product|
            format_product_info(product)
            product[:formated_price] = pretty_print_price(product['price'])
        end

        erb(:"product/products")
    end

    ##
    # @method GET /products/:product_id
    # @route GET /products/:product_id
    # Displays a single product based on its ID.
    #
    # @param product_id [Integer] The ID of the product to display.
    # @return [void]
    get '/products/:product_id' do |product_id|
        @product = select_products_and_combine_images(product_id).first
        @product[:formated_price] = pretty_print_price(@product["price"])
        format_product_info(@product)

        erb(:"product/show")
    end

    ##
    # @method GET /products/new
    # @route GET /products/new
    # Renders the product creation page.
    #
    # @return [void]
    get '/products/new' do 
        erb(:"product/new")
    end

    ##
    # @method POST /products
    # @route POST /products
    # Creates a new product based on the provided parameters.
    #
    # @return [void]
    # @example Successful product creation
    #   POST /products
    #
    post '/products' do 
        authenticate_admin()

        # Access form fields
        title = params['title']
        price = params['price']
        product_type = params['product_type']
        model_year = params['model_year']
        gear_box = params['gear_box']
        brand = params['brand']
        fuel = params['fuel']
        horse_power = params['horse_power']
        milage_km = params['milage_km']
        exterior_color = params['exterior_color']
        condition = params['condition']
        description = params['description']

        # Insert product into the database
        new_product([title, description, price, model_year, gear_box, brand, fuel, horse_power, milage_km, exterior_color, product_type, condition])

        # Get the product ID for the uploaded images
        product_id = db.last_insert_row_id

        # Store images for the product
        store_new_product_images(params["new_images"], product_id)

        # Redirect back to the admin page
        redirect("/products/#{product_id}")
    end

    ##
    # @method POST /products/:product_id/delete
    # @route POST /products/:product_id/delete
    # Deletes a product from the database and removes its associated images.
    #
    # @param product_id [Integer] The ID of the product to delete.
    # @return [void]
    post "/products/:product_id/delete" do |product_id|
        authenticate_admin()

        delete_product(product_id)
        remove_product_image_folder(product_id)

        redirect("/admin/products")
    end

    ##
    # @method GET /products/:id/edit
    # @route GET /products/:id/edit
    # Renders the product editing page.
    #
    # @param id [Integer] The ID of the product to edit.
    # @return [void]
    get "/products/:id/edit" do |id|
        authenticate_admin()

        @product = select_products_and_combine_images(id).first

        erb(:"product/edit")
    end

    ##
    # @method POST /products/:id/update
    # @route POST /products/:id/update
    # Updates a product with the new parameters.
    #
    # @param id [Integer] The ID of the product to update.
    # @return [void]
    post "/products/:id/update" do |id|
        authenticate_admin()

        # Access form fields
        title = params['title']
        price = params['price']
        product_type = params['product_type']
        model_year = params['model_year']
        gear_box = params['gear_box']
        brand = params['brand']
        fuel = params['fuel']
        horse_power = params['horse_power']
        milage_km = params['milage_km']
        exterior_color = params['exterior_color']
        condition = params['condition']
        description = params['description']

        # Update product in the database
        update_product([title, description, price, model_year, gear_box, brand, fuel, horse_power, milage_km, exterior_color, product_type, condition, id])

        # Store new product images if provided
        store_new_product_images(params['new_images'], id) if params['new_images']

        # Sort images and remove old ones if necessary
        sort_images_and_remove_rest(params[:images_order].split(","), id) if params[:images_order]

        redirect("/products/#{id}")
    end

    ##
    # @method GET /error
    # @route GET /error
    # Renders the error page.
    #
    # @return [void]
    get "/error" do 
        erb(:"error")
    end

    ##
    # @method GET /log_in
    # @route GET /log_in
    # Renders the login page for users.
    #
    # @return [void]
    get '/log_in' do
        erb(:"log_in")
    end

    ##
    # @method POST /log_in
    # @route POST /log_in
    # Logs in a user and starts a session.
    #
    # @return [void]
    # @example Successful login
    #   POST /log_in
    #
    # @example Failed login (invalid credentials)
    #   POST /log_in -> 401 Invalid credentials
    #
    post '/log_in' do
        ip = request.ip
        FAILED_ATTEMPTS[ip] ||= { count: 0, last_attempt: nil }

        # Reset failed attempts after 24 hours
        if FAILED_ATTEMPTS[ip][:last_attempt] && Time.now - FAILED_ATTEMPTS[ip][:last_attempt] > 3600*24
            FAILED_ATTEMPTS[ip] = { count: 0, last_attempt: nil }
        end

        # Enforce rate limit for login attempts (max 1 attempt within 1 minute)
        if FAILED_ATTEMPTS[ip][:count] >= 1 && Time.now - FAILED_ATTEMPTS[ip][:last_attempt] < 60
            halt erb(:error, locals: { message: "Too many attempts. Try again later.", status: 429, route: "/log_in"})
        end

        user_name_email = params['user_name_email']
        cleartext_password = params['password'] 

        user = get_user(user_name_email)

        password_from_db = BCrypt::Password.new(user['password'])

        # Check if password matches
        if password_from_db == cleartext_password 
            session[:user_id] = user['id']
            redirect '/'
        else
            FAILED_ATTEMPTS[ip][:count] += 1
            FAILED_ATTEMPTS[ip][:last_attempt] = Time.now
            halt erb(:error, locals: { message: "Invalid credentials", status: 401, route: "/log_in"})
        end
    end

    ##
    # @method GET /sign_up
    # @route GET /sign_up
    # Renders the sign-up page for users.
    #
    # @return [void]
    get '/sign_up' do
        erb(:"sign_up")
    end

    ##
    # @method POST /sign_up
    # @route POST /sign_up
    # Creates a new user and starts a session.
    #
    # @return [void]
    # @example Successful sign-up
    #   POST /sign_up
    #
    post '/sign_up' do 
        ip = request.ip
        FAILED_ATTEMPTS[ip] ||= { count: 0, last_attempt: Time.now }

        # Reset failed attempts after 24 hours
        if FAILED_ATTEMPTS[ip][:last_attempt] && Time.now - FAILED_ATTEMPTS[ip][:last_attempt] > 3600 * 24
            FAILED_ATTEMPTS[ip] = { count: 0, last_attempt: nil }
        end

        # Enforce rate limit for sign-up attempts (max 3 within 1 minute)
        if FAILED_ATTEMPTS[ip][:count] >= 3 && Time.now - FAILED_ATTEMPTS[ip][:last_attempt] < 60
            halt erb(:error, locals: { message: "Too many attempts. Try again later.", status: 429, route: "/sign_up" })
        end

        username = params['username']
        user_email = params['user_email']
        password = params['password']
        confirm_password = params['confirm_password']

        FAILED_ATTEMPTS[ip][:count] += 1
        FAILED_ATTEMPTS[ip][:last_attempt] = Time.now

        check_username_and_email(username, user_email)

        # Validate that passwords match
        if password != confirm_password
            halt erb(:error, locals: { message: "Passwords do not match", status: 400, route: "/sign_up" })
        end

        hashed_password = BCrypt::Password.create(password)
        new_user([username, user_email, hashed_password])

        user_id = db.last_insert_row_id
        session[:user_id] = user_id

        redirect '/'
    end

    ##
    # @method GET /log_out
    # @route GET /log_out
    # Logs out the current user and destroys the session.
    #
    # @return [void]
    get '/log_out' do 
        session.destroy
        redirect("/")
    end

    # CART CRUD

    before '/cart/*' do
        redirect '/log_in' unless session[:user_id]
    end

    ##
    # @method GET /cart
    # @route GET /cart
    # Renders the user's shopping cart.
    #
    # @return [void]
    get '/cart' do 
        user_id = session[:user_id]

        @cart = get_cart_by_user(user_id)
    
        @total_cost = 0
        
        @cart.each do |product|
            product[:formated_price] = pretty_print_price(product['price'])
            @total_cost += product['price']
        end

        @total_cost_formated = pretty_print_price(@total_cost)
        
        erb(:"cart")
    end

    ##
    # @method POST /cart/:product_id/new
    # @route POST /cart/:product_id/new
    # Adds a product to the user's cart.
    #
    # @param product_id [Integer] The ID of the product to add.
    # @return [void]
    post '/cart/:product_id/new' do |product_id|
        if !product_in_cart?(session[:user_id], product_id)
            redirect("/cart")
        end
        
        new_product_in_cart(session[:user_id], product_id)

        redirect("/products/#{product_id}")
    end

    ##
    # @method POST /cart/:product_id/delete
    # @route POST /cart/:product_id/delete
    # Removes a product from the user's cart.
    #
    # @param product_id [Integer] The ID of the product to remove.
    # @return [void]
    post '/cart/:product_id/delete' do |product_id|
        remove_product_from_cart(session[:user_id], product_id)
        redirect("/cart")
    end

    # SALES CRUD
    # TO BE CONTINUED...
end
