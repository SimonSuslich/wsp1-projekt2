# require 'sqlite3'

# class Seeder

#   def self.seed!
#     p "doit"
#   end

# end

# Seeder.seed!

require 'sqlite3'

class Seeder
  
  def self.seed!
    drop_tables
    create_tables
    # populate_tables   
  end

  def self.drop_tables
    db.execute('DROP TABLE IF EXISTS todos')
    db.execute('DROP TABLE IF EXISTS categories')
    db.execute('DROP TABLE IF EXISTS todos_categories')
  end

  def self.create_tables
    db.execute('CREATE TABLE todos (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                title TEXT NOT NULL,
                description TEXT,
                due_date DATE,
                post_date DATE,
                status_complete INTEGER DEFAULT 0)')
    db.execute('CREATE TABLE categories (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                name TEXT)')
    db.execute('CREATE TABLE todos_categories (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                todo_id INTEGER,
                category_id INTEGER)')
  end

  # def self.populate_tables
  #   db.execute('INSERT INTO todos (title, description, category, due_date, post_date, status_complete) VALUES ("Thing 1", "Lala lblab bla", "Kategory", "2024-02-22", "2024-02-22", false)')
  #   db.execute('INSERT INTO todos (title, description, category, due_date, post_date, status_complete) VALUES ("Thing 2", "To do bla", "Kategory", "2024-02-22", "2024-02-22", false)')
  #   db.execute('INSERT INTO todos (title, description, category, due_date, post_date, status_complete) VALUES ("Thing 3", "CHmoki chmoki mi was ochen lyubin da tak sho vi nas uzhe zadolbali", "Kategory", "2024-02-22", "2024-02-22", true)')
  # end


  private
  def self.db
    return @db if @db
    @db = SQLite3::Database.new('db/todos.sqlite')
    @db.results_as_hash = true
    @db
  end
end


Seeder.seed!