def get_cart_by_user(user_id)
  db.execute("SELECT products.id, products.title, products.price, product_images.image_path
    FROM users 
        INNER JOIN cart 
        ON cart.user_id = users.id 
        INNER JOIN products
        ON cart.product_id = products.id
        INNER JOIN product_images
        ON products.id = product_images.product_id
    WHERE users.id = ? AND product_images.image_order = 0", user_id)
end

def product_in_cart?(user_id, product_id)
  db.execute("SELECT * FROM cart WHERE user_id=? AND product_id=?", user_id, product_id).empty?
end

def new_product_in_cart(user_id, product_id)
  db.execute("INSERT INTO cart (user_id, product_id) VALUES (?,?)", [user_id, product_id])
end

def remove_product_from_cart(user_id, product_id)
  db.execute("DELETE FROM cart WHERE product_id=? AND user_id=?", [product_id, user_id])
end