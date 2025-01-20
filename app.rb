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
    


    # configure do
    #     enable :sessions
    #     set :session_secret, SecureRandom.hex(64)
    # end

    


    def authenticated
        if !session[:user_id] 
            redirect("/user")
        end
    end

    
    get '/' do
        erb(:"index")
    end




    # BROWSE

    get '/browse' do
        @all_products =  select_products_and_combine_images()

        @all_products.each do |product|
            format_product_info(product)
            product[:formated_price] = prettyPrintPrice(product['price'])
        end

        erb(:"browse")
    end

    get '/browse/:product_id' do |product_id|
     
        @product = select_products_and_combine_images(product_id).first
        @product[:formated_price] = prettyPrintPrice(@product["price"])
        format_product_info(@product)

        erb(:"view_product")
    end


    # HELP METHODS FOR BROWSE

    
    def prettyPrintKey(str)
        result = str.split('_').map.with_index { |word, index| 
            index == 0 ? word.capitalize : word.downcase
        }.join(' ')
  
        return result
    end

    def prettyPrintPrice(price) 
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

                GROUP_CONCAT(product_images.image_path) AS image_paths
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

        p product
        product.each do |key, value|
            p key
            if !banned_key.include?(key) && value.to_s != ""
                product[:basic_info]<<{
                    header: prettyPrintKey(key),
                    value: value
                }
            end
        end
    end



    # USER LOG IN AND SIGN UP

    get '/log_in' do
        erb(:"log_in")

    end

    get '/sign_up' do
        erb(:"sign_up")

    end


    # USER CART

    get '/user/cart' do 

        erb(:"cart")
    end







# ADMIN CRUD


    get '/admin' do
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
      
        # Ensure the product folder exists
        product_folder = "public/img/products/#{product_id}"
        FileUtils.mkdir_p(product_folder)
      
        # Handle uploaded images
        if params[:images]
            # Process each uploaded file
            Array(params[:images]).each do |uploaded_file|
                # Generate a unique filename
                unique_filename = "#{SecureRandom.hex(8)}_#{uploaded_file[:filename]}"
                filepath = "/img/products/#{product_id}/#{unique_filename}" # Relative path
                absolute_path = File.join("public", filepath) # Absolute path
        
                # Save the file
                File.open(absolute_path, 'wb') do |file|
                file.write(uploaded_file[:tempfile].read)
                end
        
                # Save the file path in the database
                db.execute("INSERT INTO product_images (product_id, image_path) VALUES (?, ?)", [product_id, filepath])
            end
        end
      
        # Redirect back to the admin page
        redirect("/admin")
    end 

    get '/admin/products' do 
        all_products = db.execute("SELECT products.id, products.title,  products.price, product_images.image_path
            FROM products
                INNER JOIN product_images
                ON products.id = product_images.product_id")


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

            product[:formatked_price] = prettyPrintPrice(product["price"])
        end

        erb(:"admin_products")
    end


    post "/admin/:id/delete" do |id|
        db.execute('DELETE FROM products WHERE id=?', id)
        db.execute('DELETE FROM product_images WHERE product_id=?', id)
        db.execute('DELETE FROM cart WHERE product_id=?', id)

        folder_path = "public/img/products/#{id}"
        FileUtils.rm_rf(folder_path)
        redirect("/admin/products")
    end


    get "/admin/:id/edit" do |id|

        @product = select_products_and_combine_images(id).first

        p @product

        erb(:"edit")

    end


      

end