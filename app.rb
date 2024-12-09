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
        not_completed_todos = db.execute('SELECT todos.id, todos.title, todos.description, todos.due_date, todos.post_date, todos.status_complete, categories.name
            FROM categories 
                INNER JOIN todos_categories 
                ON todos_categories.category_id = categories.id 
                INNER JOIN todos
                ON todos_categories.todo_id = todos.id
            WHERE todos.status_complete = false 
            ORDER BY todos.id')
        completed_todos = db.execute('SELECT todos.id, todos.title, todos.description, todos.due_date, todos.post_date, todos.status_complete, categories.name
            FROM categories 
                INNER JOIN todos_categories 
                ON todos_categories.category_id = categories.id 
                INNER JOIN todos
                ON todos_categories.todo_id = todos.id
            WHERE todos.status_complete = true 
            ORDER BY todos.id')

        @not_completed_todos = []
        not_completed_todos.each_with_index do |todo, i|
            element_exists = false
            @not_completed_todos.each do |element|
                element['id'] == todo['id'] ? element_exists = true : nil
            end 

            if element_exists
                @not_completed_todos.each do |arr_todo|
                    if arr_todo['id'] == todo['id']
                        arr_todo['name'] << todo['name']
                    end
                end
            else
                todo['name'] = [todo['name']]
                @not_completed_todos << todo
            end
        end


        @completed_todos = []
        completed_todos.each_with_index do |todo, i|
            element_exists = false
            @completed_todos.each do |element|
                element['id'] == todo['id'] ? element_exists = true : nil
            end 

            if element_exists
                @completed_todos.each do |arr_todo|
                    if arr_todo['id'] == todo['id']
                        arr_todo['name'] << todo['name']
                    end
                end
            else
                todo['name'] = [todo['name']]
                @completed_todos << todo
            end
        end



        erb(:"index")


    end

    post '/todos/new' do 
        title = params['title']
        description = params['description']
        categories = params['category']
        categories = categories.split(";")
        due_date = params['due_date']

        db.execute("INSERT INTO todos (title, description, due_date, post_date) VALUES(?,?,?, DATE('now'))", [title, description, due_date])


        current_categories = db.execute('SELECT name FROM categories')

        current_categories = current_categories.map { |hash| hash["name"] }

        categories.each do |category|
            if !current_categories.include?(category)
                db.execute("INSERT INTO categories (name) VALUES(?)", category)
            end
        end 


        todo_id = db.execute("SELECT id FROM todos WHERE title = ?", title).first['id']
        

        category_ids = []
        categories.each do |category|
            category_ids << db.execute("SELECT id FROM categories WHERE name = ?", category).first['id']
        end

        category_ids.each do |category_id|
            db.execute("INSERT INTO todos_categories (todo_id, category_id) VALUES(?,?)", [todo_id, category_id])
        end

        redirect("/todos")

    end

    post '/todos/:id/delete' do | id |
        db.execute('DELETE FROM todos WHERE id = ?', id)
        db.execute('DELETE FROM todos_categories WHERE todo_id = ?', id)
        redirect("/todos")        
    end

    post '/delete-all' do
        db.execute('DELETE FROM todos')
        db.execute('DELETE FROM categories')
        db.execute('DELETE FROM todos_categories')
        redirect('/todos')
    end

    post '/todos/:id/updatestatus' do |id|
        status_complete = db.execute('SELECT status_complete FROM todos WHERE id = ?', id).first.first.last
        status_complete == 1 ? status_complete = 0 : status_complete = 1
        db.execute("UPDATE todos SET status_complete=? WHERE id=?", [status_complete, id])
        redirect("/todos")
    end

    get '/todos/:id/edit' do |id|
        todos = db.execute('SELECT todos.id, todos.title, todos.description, todos.due_date, todos.post_date, todos.status_complete, categories.name
            FROM categories 
                INNER JOIN todos_categories 
                ON todos_categories.category_id = categories.id 
                INNER JOIN todos
                ON todos_categories.todo_id = todos.id
            WHERE todos.id=?', id)


        all_categories = []
        todos.each do |todo|
            all_categories << todo['name']
        end

        @todo = todos.first

        @todo['name'] = all_categories

        @todo_categories = ""
        all_categories.each do |category|
            @todo_categories += category+";"
        end
        @todo_categories = @todo_categories.chop

        erb(:"edit")
    end
        

    post '/todos/:id/update' do |id|

        title = params['title']
        description = params['description']
        categories = params['category']
        categories = categories.split(";")
        due_date = params['due_date']
        
        db.execute("UPDATE todos SET title=?, description=?, due_date=?, post_date=DATE('now') WHERE id=?", [[title, description, due_date], id]) 

        current_categories = db.execute('SELECT name FROM categories')

        current_categories = current_categories.map { |hash| hash["name"] }

        categories.each do |category|
            if !current_categories.include?(category)
                db.execute("INSERT INTO categories (name) VALUES(?)", category)
            end
        end 


        categories_id = []
        categories.each do |category|
            categories_id << db.execute('SELECT id FROM categories WHERE name=?', category).first['id']
        end

        db.execute('DELETE FROM todos_categories WHERE todo_id=?', id)

        categories_id.each do |category_id|
            db.execute('INSERT INTO todos_categories (todo_id, category_id) VALUES(?,?)', [id, category_id])
        end

        redirect("/todos")
    end
end