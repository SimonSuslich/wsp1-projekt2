require 'securerandom'
require 'sinatra'
require 'fileutils'
require_relative 'lib/product_helpers'


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

    


    def authenticated
        if !session[:user_id] 
            redirect("/log_in")
        end
    end

    def admin_authenticated
        if !session[:admin_id]
            redirect("/admin/log_in")
        end
    end

    
    get '/' do
        redirect("/products")
    end



    get '/about' do 
        erb(:"about")
    end










    # ADMIN CRUD

    get '/admin/log_in' do 
        erb(:"admin/admin_log_in")
    end

    post '/admin/log_in' do 
        user_name_email = params['user_name_email']
        cleartext_password = params['password'] 

        user = db.execute('SELECT * FROM admin WHERE name = ?', user_name_email).first

        if !user
            user = db.execute('SELECT * FROM admin WHERE email = ?', user_name_email).first
        end

        if !user
            redirect("/error")
        end
    
        password_from_db = BCrypt::Password.new(user['password'])

        if password_from_db == cleartext_password 
            session[:admin_id] = user['id'] 
            redirect("/admin")
        else
            redirect("/error")
        end 
    end

    get '/admin' do
        admin_authenticated()
        erb(:"admin/admin")
    end


    get '/products/new' do 
        admin_authenticated()
        erb(:"product/new")
    end


    post '/products' do 
        admin_authenticated()

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
        db.execute(
            "INSERT INTO products (title, description, price, model_year, gear_box, brand, fuel, horse_power, milage_km, exterior_color, product_type, condition) 
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)", 
            [title, description, price, model_year, gear_box, brand, fuel, horse_power, milage_km, exterior_color, product_type, condition]
        )
    
        # Get the product ID for the uploaded images
        product_id = db.last_insert_row_id

        store_new_product_images(params["new_images"], product_id)

        # Redirect back to the admin page
        redirect("/products/#{product_id}")
    end 


    get '/admin/view_products' do 
        admin_authenticated()
        @all_products = db.execute("SELECT products.id, products.title,  products.price, product_images.image_path
            FROM products
                INNER JOIN product_images
                ON products.id = product_images.product_id
            WHERE product_images.image_order = 0")



        @all_products.each do |product|

            product[:formated_price] = pretty_print_price(product["price"])
        end

        p @all_products

        erb(:"admin/admin_products")
    end


    post "/products/:id/delete" do |id|
        admin_authenticated()
        db.execute('DELETE FROM products WHERE id=?', id)
        db.execute('DELETE FROM cart WHERE product_id=?', id)
        remove_product_image_folder(id)

        redirect("/products/admin")
    end



    get "/products/:id/edit" do |id|
        admin_authenticated()

        @product = select_products_and_combine_images(id).first

        erb(:"product/edit")

    end

    post "/products/:id/update" do |id|
        admin_authenticated()

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

        db.execute(
            "UPDATE products SET title=?, description=?, price=?, model_year=?, gear_box=?, brand=?, fuel=?, horse_power=?, milage_km=?, exterior_color=?, product_type=?, condition=? WHERE id=?", 
            [title, description, price, model_year, gear_box, brand, fuel, horse_power, milage_km, exterior_color, product_type, condition, id]
        )


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


    # HELP METHODS FOR BROWSE




    # USER LOG IN AND SIGN UP

    get "/error" do 
        erb(:"error")
    end

    get '/log_in' do
        erb(:"log_in")
    end

    post '/log_in' do
        user_name_email = params['user_name_email']
        cleartext_password = params['password'] 
      

        user = db.execute('SELECT * FROM users WHERE username = ?', user_name_email).first



        if !user
            user = db.execute('SELECT * FROM users WHERE user_email = ?', user_name_email).first
        end


        if !user
            redirect("/error")
        end
      
        password_from_db = BCrypt::Password.new(user['password'])

        if password_from_db == cleartext_password 
            session[:user_id] = user['id'] 
            redirect("/")
        else
            redirect("/error")

        end 
    end

    get '/sign_up' do
        erb(:"sign_up")
    end

    post '/sign_up' do 
        username = params['username']
        user_email = params['user_email']
        password = params['password']
        confirm_password = params['confirm_password']


        check_username(username)


        if password != confirm_password
            redirect("/error")
        end


        hashed_pasword = BCrypt::Password.create(password)

        db.execute("INSERT INTO users (username, user_email, password) 
            VALUES (?, ?, ?)
            ", [username, user_email, hashed_pasword])

        user_id = db.last_insert_row_id
        session[:user_id] = user_id 


        redirect("/")
    end

    def check_username(username)
        username_list = db.execute("SELECT username FROM users WHERE username=?", username)

        if !username_list.empty?
            redirect("/error")
        end
    end

    get '/log_out' do 
        session.destroy
        redirect("/")
    end


    # USER CART

    get '/cart' do 

        user_id = session[:user_id]

        @cart = db.execute("SELECT products.id, products.title, products.price, product_images.image_path
            FROM users 
                INNER JOIN cart 
                ON cart.user_id = users.id 
                INNER JOIN products
                ON cart.product_id = products.id
                INNER JOIN product_images
                ON products.id = product_images.product_id
            WHERE users.id = ? AND product_images.image_order = 0", user_id)
    

        
        @total_cost = 0
        @cart.each do |product|
            product[:formated_price] = pretty_print_price(product['price'])
            @total_cost += product['price']
        end

        @total_cost_formated = pretty_print_price(@total_cost)

        p @cart.empty?



        
        erb(:"cart")
    end

    get '/cart/:product_id/new' do |product_id|
        authenticated()

        sql_prompt = db.execute("SELECT * FROM cart WHERE user_id=? AND product_id=?", [session[:user_id], product_id])

        if !sql_prompt.empty?
            redirect("/cart")
        end
        
        db.execute("INSERT INTO cart (user_id, product_id) VALUES (?,?)", [session[:user_id], product_id])
        
        redirect("/cart")
    end

    post '/cart/:product_id/delete' do |product_id|
        db.execute("DELETE FROM cart WHERE product_id=? AND user_id=?", [product_id, session[:user_id]])

        redirect("/cart")
    end








end