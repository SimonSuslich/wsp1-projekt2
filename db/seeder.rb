require 'sqlite3'
require_relative '../lib/product_helpers'

class Seeder
  
  def self.seed!
    drop_tables
    create_tables
    create_admin
    clear_products_folder()
  end

  def self.drop_tables
    db.execute('DROP TABLE IF EXISTS products')
    db.execute('DROP TABLE IF EXISTS product_images')
    db.execute('DROP TABLE IF EXISTS users')
    db.execute('DROP TABLE IF EXISTS cart')
    db.execute('DROP TABLE IF EXISTS admin')
    db.execute('DROP TABLE IF EXISTS sales')
  end

  def self.create_tables

    db.execute('PRAGMA foreign_keys = ON')  # Ensure foreign keys are enforced

    db.execute('CREATE TABLE products (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                title TEXT NOT NULL,
                description TEXT,
                price INTEGER NOT NULL,
                model_year INTEGER,
                gear_box TEXT,
                brand TEXT,
                fuel TEXT,
                horse_power TEXT,
                milage_km INTEGER,
                exterior_color TEXT,
                product_type TEXT,
                condition TEXT)')

    db.execute('CREATE TABLE product_images (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                product_id INTEGER NOT NULL,
                image_path TEXT NOT NULL,
                image_order INTEGER NOT NULL,
                FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE)')

    db.execute('CREATE TABLE users (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                username TEXT,
                user_email TEXT, 
                password TEXT NOT NULL)')

    db.execute('CREATE TABLE cart (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                user_id INTEGER NOT NULL,
                product_id INTEGER NOT NULL,
                FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE)')

    db.execute('CREATE TABLE admin (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                name TEXT,
                email TEXT,
                password TEXT NOT NULL)')
                
    db.execute('CREATE TABLE sales (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                buyer TEXT,
                product_id TEXT,
                FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE)')
  end

  def self.create_admin
    db.execute('INSERT INTO admin (name, email, password) VALUES (?,?,?)', ["admin", "simonniklas.suslich@elev.ga.ntig.se", BCrypt::Password.create("admin")])
  end


  private
  def self.db
    return @db if @db
    @db = SQLite3::Database.new('db/vcars.sqlite')
    @db.results_as_hash = true
    @db
  end
end


Seeder.seed!
