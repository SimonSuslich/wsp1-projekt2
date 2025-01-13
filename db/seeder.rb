require 'sqlite3'

class Seeder
  
  def self.seed!
    drop_tables
    create_tables
  end

  def self.drop_tables
    db.execute('DROP TABLE IF EXISTS products')
    db.execute('DROP TABLE IF EXISTS product_images')
    db.execute('DROP TABLE IF EXISTS sales')
    db.execute('DROP TABLE IF EXISTS users')
  end

  def self.create_tables
    db.execute('CREATE TABLE products (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                title TEXT NOT NULL,
                description TEXT,
                price INTEGER NOT NULL,
                model_year INTEGER,
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
                image_path TEXT NOT NULL)')
    db.execute('CREATE TABLE sales (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                todo_id INTEGER,
                category_id INTEGER)')
    db.execute('CREATE TABLE users (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                username TEXT,
                password TEXT NOT NULL)')
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