require 'securerandom'
require 'sinatra'
require 'fileutils'
require 'time'
require_relative 'lib/product_helpers'
require_relative 'lib/user_helpers'
require_relative 'lib/admin_helpers'
require_relative 'lib/cart_helpers'


class App < Sinatra::Base



    # Funktion som returnerar en databaskoppling
    # Exempel på användning: db.execute('SELECT * FROM fruits')
    def db
        return @db if @db

        @db = SQLite3::Database.new("db/vcars.sqlite")
        @db.results_as_hash = true

        return @db
    end



    configure do
        enable :sessions
        set :session_secret, SecureRandom.hex(64)
    end

    get '/' do
        redirect("/products")
    end

    get '/about' do 
        erb(:"about")
    end



    # ADMIN CRUD

    before '/admin/*' do
        pass if request.path_info == '/admin/log_in'
        redirect '/admin/log_in' unless session[:admin_id]
    end
      
      

    get '/admin/log_in' do 
        erb(:"admin/log_in")
    end


    FAILED_ATTEMPTS ||= {}  

    post '/admin/log_in' do
        ip = request.ip
        FAILED_ATTEMPTS[ip] ||= { count: 0, last_attempt: nil }
        
        if FAILED_ATTEMPTS[ip][:last_attempt] && Time.now - FAILED_ATTEMPTS[ip][:last_attempt] > 24*3600
            FAILED_ATTEMPTS[ip] = { count: 0, last_attempt: nil }
        end
        
        if FAILED_ATTEMPTS[ip][:count] >= 3
            if FAILED_ATTEMPTS[ip][:last_attempt] && Time.now - FAILED_ATTEMPTS[ip][:last_attempt] < 60
                halt erb(:error, locals: { message: "Too many attempts. Try again later.", status: 429, route: "/admin/log_in" })
            end
        end
    
        admin_name_email = params['name_email']
        cleartext_password = params['password'] 
    
        admin = get_admin(admin_name_email)
    
        password_from_db = BCrypt::Password.new(admin['password'])
    
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
    

    get '/admin/dashboard' do
        erb(:"admin/dashboard")
    end


    get '/products/new' do 
        erb(:"product/new")
    end


    post '/products' do 

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

        store_new_product_images(params["new_images"], product_id)

        # Redirect back to the admin page
        redirect("/products/#{product_id}")
    end 


    get '/admin/products' do 
        @all_products = admin_view_products()

        @all_products.each do |product|
            product[:formated_price] = pretty_print_price(product["price"])
        end

        erb(:"admin/products")
    end


    post "/products/:product_id/delete" do |product_id|

        delete_product(product_id)
        remove_product_image_folder(product_id)

        redirect("/admin/products")
    end



    get "/products/:id/edit" do |id|

        @product = select_products_and_combine_images(id).first

        erb(:"product/edit")

    end

    post "/products/:id/update" do |id|

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

        update_product([title, description, price, model_year, gear_box, brand, fuel, horse_power, milage_km, exterior_color, product_type, condition, id])


        store_new_product_images(params['new_images'], id) if params['new_images']

        sort_images_and_remove_rest(params[:images_order].split(","), id) if params[:images_order]

        redirect("/products/#{id}")
        

    end



    # products

    get '/products' do
        @all_products =  select_products_and_combine_images()

        @all_products.each do |product|
            format_product_info(product)
            product[:formated_price] = pretty_print_price(product['price'])
        end

        erb(:"product/products")
    end

    get '/products/:product_id' do |product_id|
        @product = select_products_and_combine_images(product_id).first
        @product[:formated_price] = pretty_print_price(@product["price"])
        format_product_info(@product)

        erb(:"product/show")
    end




    # USER LOG IN AND SIGN UP

    get "/error" do 
        erb(:"error")
    end

    get '/log_in' do
        erb(:"log_in")
    end




    post '/log_in' do
        ip = request.ip
        FAILED_ATTEMPTS[ip] ||= { count: 0, last_attempt: nil }
        
        if FAILED_ATTEMPTS[ip][:last_attempt] && Time.now - FAILED_ATTEMPTS[ip][:last_attempt] > 3600*24
            FAILED_ATTEMPTS[ip] = { count: 0, last_attempt: nil }
        end

        if FAILED_ATTEMPTS[ip][:count] >= 1 && Time.now - FAILED_ATTEMPTS[ip][:last_attempt] < 60
          halt erb(:error, locals: { message: "Too many attempts. Try again later.", status: 429, route: "/log_in"})
        end
      
        user_name_email = params['user_name_email']
        cleartext_password = params['password'] 

        user = get_user(user_name_email)
      
        password_from_db = BCrypt::Password.new(user['password'])

        if password_from_db == cleartext_password 
          session[:user_id] = user['id']
          redirect '/'
        else
          FAILED_ATTEMPTS[ip][:count] += 1
          FAILED_ATTEMPTS[ip][:last_attempt] = Time.now
          halt erb(:error, locals: { message: "Invalid credentials", status: 401, route: "/log_in"})
        end
    end

    get '/sign_up' do
        erb(:"sign_up")
    end

    post '/sign_up' do 
        ip = request.ip
        FAILED_ATTEMPTS[ip] ||= { count: 0, last_attempt: Time.now }
    
        if FAILED_ATTEMPTS[ip][:last_attempt] && Time.now - FAILED_ATTEMPTS[ip][:last_attempt] > 3600 * 24
            FAILED_ATTEMPTS[ip] = { count: 0, last_attempt: nil }
        end

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
    
        if password != confirm_password

            halt erb(:error, locals: { message: "Passwords do not match", status: 400, route: "/sign_up" })
        end
    
        hashed_password = BCrypt::Password.create(password)
        new_user([username, user_email, hashed_password])
    
        user_id = db.last_insert_row_id
        session[:user_id] = user_id


        redirect '/'
    end
    
    get '/log_out' do 
        session.destroy
        redirect("/")
    end


    # CART CRUD

    before '/cart/*' do
        redirect '/log_in' unless session[:user_id]
    end

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

    post '/cart/:product_id/new' do |product_id|
        if !product_in_cart?(session[:user_id], product_id)
            redirect("/cart")
        end
        
        new_product_in_cart(session[:user_id], product_id)

        redirect("/products/#{product_id}")
    end

    post '/cart/:product_id/delete' do |product_id|
        remove_product_from_cart(session[:user_id], product_id)
        redirect("/cart")
    end



    #SALES CRUD

    #TO BE CONTINUED




end