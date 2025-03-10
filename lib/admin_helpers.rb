def get_admin(name_or_email)
  admin = db.execute('SELECT * FROM admin WHERE name = ?', name_or_email).first
  if !admin
    admin = db.execute('SELECT * FROM admin WHERE email = ?', name_or_email).first
  end

  return admin if admin

  redirect("/error")
  return nil

end

def admin_authenticated
  if !session[:admin_id]
    redirect("/admin/log_in")
  end
end

def admin_view_products
  db.execute("SELECT products.id, products.title,  products.price, product_images.image_path
    FROM products
        INNER JOIN product_images
        ON products.id = product_images.product_id
    WHERE product_images.image_order = 0")
end