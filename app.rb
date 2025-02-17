require 'securerandom'
require 'sinatra'
require 'fileutils'


class App < Sinatra::Base



    # Funktion som returnerar en databaskoppling
    # Exempel på användning: db.execute('SELECT * FROM fruits')
    def db
        return @db if @db

        @db = SQLite3::Database.new("db/vcars.sqlite")
        @db.results_as_hash = true

        return @db
    end


    def clear_products_folder(folder_path="public/img/products")
        if Dir.exist?(folder_path)
            # Remove all contents (files and subfolders)
            FileUtils.rm_rf(Dir.glob("#{folder_path}/*"))
            puts "Cleared all contents of the products folder."
        else
            puts "The products folder does not exist."
        end
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
        authenticated()
        erb(:"index")
    end



    get '/about' do 
        erb(:"about")
    end


    # BROWSE

    get '/browse' do
        @all_products =  select_products_and_combine_images()

        @all_products.each do |product|
            format_product_info(product)
            product[:formated_price] = pretty_print_price(product['price'])
        end

        erb(:"browse")
    end

    get '/browse/:product_id' do |product_id|
     
        @product = select_products_and_combine_images(product_id).first
        @product[:formated_price] = pretty_print_price(@product["price"])
        format_product_info(@product)

        erb(:"view_product")
    end


    # HELP METHODS FOR BROWSE

    
    def pretty_print_key(str)
        result = str.split('_').map.with_index { |word, index| 
            index == 0 ? word.capitalize : word.downcase
        }.join(' ')
  
        return result
    end

    def pretty_print_price(price) 
        str_price = price.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1 ').reverse
    end

    def select_products_and_combine_images(product_id = nil)

        sqlPrompt = 'SELECT 
                products.id, 
                products.product_type, 
                products.title, 
                products.price, 
                products.model_year, 
                products.brand, 
                products.fuel, 
                products.horse_power, 
                products.milage_km, 
                products.exterior_color, 
                products.condition, 
                products.description, 

                GROUP_CONCAT(product_images.image_path ORDER BY product_images.image_order) AS image_paths
            FROM 
                products
            INNER JOIN 
                product_images 
            ON 
                products.id = product_images.product_id
            '

        if product_id
            sqlPrompt << "WHERE products.id=#{product_id}"
        end

        sqlPrompt << "            GROUP BY 
        products.id"

        all_products = db.execute(sqlPrompt)

        all_products.each do |product|
            product['image_paths'] = product['image_paths'].split(',')
        end

    end

    def format_product_info(product)
        banned_key = ["title", "product_type", "description", "id", "price", "image_paths", :formated_price, :basic_info]

        product[:basic_info] = []

        product.each do |key, value|
            if !banned_key.include?(key) && value.to_s != ""
                product[:basic_info]<<{
                    header: pretty_print_key(key),
                    value: value
                }
            end
        end
    end



    # USER LOG IN AND SIGN UP

    get "/error" do 
        erb(:"error")
    end

    get '/log_in' do
        erb(:"log_in")
    end

    post '/log_in' do
        username = params['username']
        user_email = params['user_email']
        cleartext_password = params['password'] 
      

        user = db.execute('SELECT * FROM users WHERE username = ?', username).first



        if !user
            user = db.execute('SELECT * FROM users WHERE user_email = ?', user_email).first
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

    get '/user/cart' do 

        erb(:"cart")
    end

    get '/add_to_cart/:product_id' do |product_id|
        
        db.execute("INSERT INTO cart (user_id, product_id) VALUES (?,?)", [session[:user_id], product_id])
        
        redirect("/user/cart")
    end







# ADMIN CRUD

    get '/admin/log_in' do 
        erb(:"admin_log_in")
    end

    post '/admin/log_in' do 
        username = params['username']
        cleartext_password = params['password'] 

        user = db.execute('SELECT * FROM admin WHERE name = ?', username).first

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
        erb(:"admin")
    end


    get '/admin/delete_all_images' do
        clear_products_folder()
        redirect("/admin")
    end


    get '/admin/create_new_product' do 
        erb(:"new_product")
    end


    post '/admin/create_new_product' do 

        # Access form fields
        title = params['title']
        price = params['price']
        product_type = params['product_type']
        model_year = params['model_year']
        brand = params['brand']
        fuel = params['fuel']
        horse_power = params['horse_power']
        milage_km = params['milage_km']
        exterior_color = params['exterior_color']
        condition = params['condition']
        description = params['description']
      
        # Insert product into the database
        db.execute(
            "INSERT INTO products (title, description, price, model_year, brand, fuel, horse_power, milage_km, exterior_color, product_type, condition) 
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)", 
            [title, description, price, model_year, brand, fuel, horse_power, milage_km, exterior_color, product_type, condition]
        )
      
        # Get the product ID for the uploaded images
        product_id = db.last_insert_row_id

        store_new_product_images(params["new_images"], product_id)

        # Redirect back to the admin page
        redirect("/browse/#{product_id}")
    end 


    get '/admin/products' do 
        all_products = db.execute("SELECT products.id, products.title,  products.price, product_images.image_path
            FROM products
                INNER JOIN product_images
                ON products.id = product_images.product_id
            ORDER BY product_images.image_order")


        @all_products = []

        all_products.each_with_index do |product, i|
            element_exists = false
            @all_products.each do |element|
                element['id'] == product['id'] ? element_exists = true : nil
            end 

            if element_exists
                @all_products.each do |arr_product|
                    if arr_product['id'] == product['id']
                        arr_product['image_path'] << product['image_path']
                    end
                end
            else
                product['image_path'] = [product['image_path']]
                @all_products << product
            end

            product[:formatked_price] = pretty_print_price(product["price"])
        end

        erb(:"admin_products")
    end


    post "/admin/:id/delete" do |id|
        db.execute('DELETE FROM products WHERE id=?', id)
        db.execute('DELETE FROM cart WHERE product_id=?', id)
        remove_product_image_folder(id)

        redirect("/admin/products")
    end

    def remove_product_image_folder(product_id)
        db.execute('DELETE FROM product_images WHERE product_id=?', product_id)
        folder_path = "public/img/products/#{product_id}"
        FileUtils.rm_rf(folder_path)
    end

    def store_new_product_images(images, product_id)

        # Ensure the product folder exists
        product_folder = "public/img/products/#{product_id}"
        FileUtils.mkdir_p(product_folder)
      
        # Handle uploaded images
        if images
            # Process each uploaded file
            Array(images).each_with_index do |uploaded_file, index|
                # Generate a unique filename
                unique_filename = "#{SecureRandom.hex(8)}_#{uploaded_file[:filename]}"
                filepath = "/img/products/#{product_id}/#{unique_filename}" # Relative path
                absolute_path = File.join("public", filepath) # Absolute path
        
                # Save the file
                File.open(absolute_path, 'wb') do |file|
                    file.write(uploaded_file[:tempfile].read)
                end
                # Save the file path in the database
                db.execute("INSERT INTO product_images (product_id, image_path, image_order) VALUES (?, ?, ?)", [product_id, filepath, index])
            end
        end
    end


    def sort_images_and_remove_rest(images_order, product_id)
        all_images = db.execute("SELECT image_path, id FROM product_images WHERE product_id=?", product_id)
    
        # Extract meaningful names from image paths
        all_images.each do |image|
            image["img_name"] = image["image_path"].split("/")[-1].split("_")[1..-1].join("_")
        end
    
        # Create a mutable list to track available images
        available_images = all_images.dup
    
        # Find matching images while ensuring uniqueness
        matching_images = images_order.map do |name|
            match = available_images.find { |img| img["img_name"] == name }
            available_images.delete(match) if match # Remove used match to prevent duplicates
            match
        end.compact
    
        # Get remaining non-matching images
        non_matching_images = available_images
    
        puts "Matching Images: #{matching_images}"
        puts "Non-matching Images: #{non_matching_images}"
    
        # Update image order
        matching_images.each_with_index do |img, i|
            db.execute("UPDATE product_images SET image_order=? WHERE id=?", [i, img['id']])
        end
    
        # Remove unmatched images
        non_matching_images.each do |img|
            db.execute("DELETE FROM product_images WHERE id=?", img['id'])
            FileUtils.rm("public#{img['image_path']}")
        end
    end
    

    get "/admin/:id/edit" do |id|

        @product = select_products_and_combine_images(id).first

        erb(:"edit")

    end

    post "/admin/:id/update" do |id|

        # Access form fields
        title = params['title']
        price = params['price']
        product_type = params['product_type']
        model_year = params['model_year']
        brand = params['brand']
        fuel = params['fuel']
        horse_power = params['horse_power']
        milage_km = params['milage_km']
        exterior_color = params['exterior_color']
        condition = params['condition']
        description = params['description']

        db.execute(
            "UPDATE products SET title=?, description=?, price=?, model_year=?, brand=?, fuel=?, horse_power=?, milage_km=?, exterior_color=?, product_type=?, condition=? WHERE id=?", 
            [title, description, price, model_year, brand, fuel, horse_power, milage_km, exterior_color, product_type, condition, id]
        )
    

        store_new_product_images(params['new_images'], id) if params['new_images']

        sort_images_and_remove_rest(params[:images_order].split(","), id) if params[:images_order]
    
        redirect("/browse/#{id}")
        

    end

end