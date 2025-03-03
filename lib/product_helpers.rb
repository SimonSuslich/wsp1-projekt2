
def clear_products_folder(folder_path="public/img/products")
  if Dir.exist?(folder_path)
    # Remove all contents (files and subfolders)
    FileUtils.rm_rf(Dir.glob("#{folder_path}/*"))
    puts "Cleared all contents of the products folder."
  else
    puts "The products folder does not exist."
  end
end

def remove_product_image_folder(product_id)
  admin_authenticated()
  db.execute('DELETE FROM product_images WHERE product_id=?', product_id)
  folder_path = "public/img/products/#{product_id}"
  FileUtils.rm_rf(folder_path)
end

def store_new_product_images(images, product_id)
  admin_authenticated()

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
  admin_authenticated()
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
            products.gear_box, 
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