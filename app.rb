class App < Sinatra::Base

    # Funktion som returnerar en databaskoppling
    # Exempel på användning: db.execute('SELECT * FROM fruits')
    def db
        return @db if @db

        @db = SQLite3::Database.new("db/todos.sqlite")
        @db.results_as_hash = true

        return @db
    end


    
    # Routen gör en redirect till '/fruits'
    get '/' do
        redirect("/todos")
    end


    #Routen hämtar alla frukter i databasen
    get '/todos' do
        @not_completed_todos = db.execute('SELECT todos.id, todos.title, todos.description, todos.due_date, todos.post_date, todos.status_complete, categories.name
            FROM categories 
                INNER JOIN todos_categories 
                ON todos_categories.category_id = categories.id 
                INNER JOIN todos
                ON todos_categories.todo_id = todos.id
            WHERE todos.status_complete = false 
            ORDER BY todos.id')
        @completed_todos = db.execute('SELECT todos.id, todos.title, todos.description, todos.due_date, todos.post_date, todos.status_complete, categories.name
            FROM categories 
                INNER JOIN todos_categories 
                ON todos_categories.category_id = categories.id 
                INNER JOIN todos
                ON todos_categories.todo_id = todos.id
            WHERE todos.status_complete = true 
            ORDER BY todos.id')

        erb(:"index")

        # category_id = db.execute("SELECT category_id FROM todos_categories WHERE todo_id=?", todo_id).first['category_id']


    end

    post '/todos' do 
        title = params['title']
        description = params['description']
        categories = params['category']
        categories = categories.split(";")
        due_date = params['due_date']

        db.execute("INSERT INTO todos (title, description, due_date, post_date) VALUES(?,?,?, DATE('now'))", [title, description, due_date])


        categories.each do |category|
            db.execute("INSERT INTO categories (name) VALUES(?)", category)
        end 


        todo_id = db.execute("SELECT id FROM todos WHERE title = ?", title).first['id']
        

        category_ids = []
        categories.each do |category|
            category_ids << db.execute("SELECT id FROM categories WHERE name = ?", category).first['id']
        end

        p category_ids

        category_ids.each do |category_id|
            p todo_id
            p category_id
            db.execute("INSERT INTO todos_categories (todo_id, category_id) VALUES(?,?)", [todo_id, category_id])
        end




        redirect("/")

    end

    post '/todos/:id/delete' do | id |
        db.execute('DELETE FROM todos WHERE id = ?', id)
        redirect("/todos")        
    end

    post '/todos/:id/updatestatus' do |id|
        status_complete = db.execute('SELECT status_complete FROM todos WHERE id = ?', id).first.first.last
        status_complete == 1 ? status_complete = 0 : status_complete = 1
        db.execute("UPDATE todos SET status_complete=? WHERE id=?", [status_complete, id])
        redirect("/")
    end

    get '/todos/:id/edit' do |id|
        @todo = db.execute('SELECT * FROM todos WHERE id=?', id).first
        erb(:"edit")
    end
        

    post '/todos/:id/update' do |id|

        title = params['title']
        description = params['description']
        category = params['category']
        due_date = params['due_date']
        
        db.execute("UPDATE todos SET title=?, description=?, due_date=?, post_date=DATE('now') WHERE id=?", [[title, description, due_date], id])
        redirect("/")

    end



end