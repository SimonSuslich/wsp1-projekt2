require 'securerandom'
require 'sinatra'
require 'fileutils' # For creating directories


class App < Sinatra::Base



    # Funktion som returnerar en databaskoppling
    # Exempel på användning: db.execute('SELECT * FROM fruits')
    def db
        return @db if @db

        @db = SQLite3::Database.new("db/vcars.sqlite")
        @db.results_as_hash = true

        return @db
    end


    def clear_products_folder
        folder_path = "public/img/products"
    
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



    get '/admin/delete_all_images' do
        clear_products_folder()
        redirect("/admin")
    end


    get '/browse' do

        all_products = db.execute("SELECT products.id, products.title, products.description, products.brand, products.price, products.model_year, products.fuel, products.horse_power, products.milage_km, products.exterior_color, products.product_type, products.condition, product_images.image_path
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
        end


        @all_products.each do |product|
            basic_info = []
            banned_key = ["title", "product_type", "description", "id", "price", "image_path"]

            product.each do |key, value|
                if !banned_key.include?(key) && value.to_s != ""
                    element = {
                        header: prettyPrintKey(key),
                        value: value
                    }
                    basic_info << element

                end
            end

            product[:basic_info] = basic_info

        end

        erb(:"browse")
    end


    def prettyPrintKey(str)
        # Split, capitalize the first word, and downcase the rest
        result = str.split('_').map.with_index { |word, index| 
            index == 0 ? word.capitalize : word.downcase
        }.join(' ')
  
        return result
    end

    get '/admin' do
        erb(:"admin")
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
                filepath = "img/products/#{product_id}/#{unique_filename}" # Relative path
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
      

end