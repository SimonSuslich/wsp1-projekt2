def get_admin(name_or_email)
  admin = db.execute('SELECT * FROM admin WHERE name = ? OR email = ?', [name_or_email, name_or_email]).first
  return admin if admin
  halt erb(:error, locals: { message: "Invalid credentials", status: 401, route: "/admin/log_in" })
end

def admin_view_products
  db.execute("SELECT products.id, products.title,  products.price, product_images.image_path
    FROM products
        INNER JOIN product_images
        ON products.id = product_images.product_id
    WHERE product_images.image_order = 0")
end

def authenticate_admin
  redirect '/admin/log_in' unless session[:admin_id]
end