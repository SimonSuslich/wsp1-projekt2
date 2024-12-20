require 'securerandom'
require 'sinatra'

class App < Sinatra::Base



    # Funktion som returnerar en databaskoppling
    # Exempel på användning: db.execute('SELECT * FROM fruits')
    def db
        return @db if @db

        @db = SQLite3::Database.new("db/todos.sqlite")
        @db.results_as_hash = true

        return @db
    end


    configure do
        enable :sessions
        set :session_secret, SecureRandom.hex(64)
    end

    

    get '/' do
        redirect("/user")
    end

    def authenticated
        if !session[:user_id] 
            redirect("/user")
        end
    end


    def getTodos(filter=nil, sort="todos.id")
        

        all_todos = []

        [false, true].each do |bool|
            db_execute_string = 'SELECT todos.id, todos.title, todos.description, todos.due_date, todos.post_date, todos.status_complete, categories.name
            FROM categories 
                INNER JOIN todos_categories 
                ON todos_categories.category_id = categories.id 
                INNER JOIN todos
                ON todos_categories.todo_id = todos.id
            WHERE todos.status_complete = ' + bool.to_s

            filter!=nil ? db_execute_string += " AND categories.id = " + filter.to_s : nil

            db_execute_string += "\nORDER BY " + sort

            all_todos << db.execute(db_execute_string)

        end
        
        not_completed_todos, completed_todos = all_todos

        return_todos = [[], []]

        all_todos.each_with_index do |big_todo, j|

            big_todo.each_with_index do |todo, i|
                element_exists = false
                return_todos[j].each do |element|
                    element['id'] == todo['id'] ? element_exists = true : nil
                end 

                if element_exists
                    return_todos[j].each do |arr_todo|
                        if arr_todo['id'] == todo['id']
                            p todo['name']
                            arr_todo['name'] << todo['name']
                        end
                    end
                else
                    todo['name'] = [todo['name']]
                    return_todos[j] << todo
                end
            end

        end

        return return_todos

    end



    #Routen hämtar alla todos i databasen
    get '/todos' do

        authenticated()

        @not_completed_todos, @completed_todos = getTodos()

        @all_categories = db.execute('SELECT * FROM categories')
        p @all_categories

        erb(:"index")
    end

    post '/todos/sort' do 
        sort_info = params['sort_info']

        if sort_info.to_s == "-"
            redirect("/todos")
        end

        redirect_to = '/todos/sort/' + sort_info.to_s
        redirect(redirect_to)   
    end

    get '/todos/sort/:sort_info' do |sort_info|



    end


    post '/todos/filter-sort' do
        sort_info = params['sort_info']
        category_id = params['category']


        redirect_to = '/todos/filter-sort/' + category_id.to_s + '/' + sort_info.to_s
        redirect(redirect_to)   

    end

    get '/todos/filter-sort/:category_id/:sort_info' do |category_id, sort_info|

        authenticated()

        if category_id.to_s == "-" && sort_info == "-"
            redirect('/todos')
        end

        category_id.to_s == "-" ? category_id = nil : nil

        case sort_info
        when "due-date-inc" then sort_info = "todos.due_date ASC"
        when "due-date-dec" then sort_info = "todos.due_date DESC"
        when "post-date-dec" then sort_info = "todos.post_date DESC"
        when "post-date-inc" then sort_info = "todos.post_date ASC"
        when "titel" then sort_info = "todos.title"
        when "category" then sort_info = "categories.name"
        else sort_info = "todos.id"
        end
        

        @not_completed_todos, @completed_todos = getTodos(filter=category_id, sort=sort_info)

        @all_categories = db.execute('SELECT * FROM categories')
        p @all_categories

        erb(:'index')
    end

    post '/todos/new' do 

        authenticated()


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

        authenticated()

        db.execute('DELETE FROM todos WHERE id = ?', id)
        db.execute('DELETE FROM todos_categories WHERE todo_id = ?', id)
        redirect("/todos")        
    end

    post '/delete-all' do

        authenticated()

        db.execute('DELETE FROM todos')
        db.execute('DELETE FROM categories')
        db.execute('DELETE FROM todos_categories')
        redirect('/todos')
    end

    post '/todos/:id/updatestatus' do |id|

        authenticated()

        status_complete = db.execute('SELECT status_complete FROM todos WHERE id = ?', id).first.first.last
        status_complete == 1 ? status_complete = 0 : status_complete = 1
        db.execute("UPDATE todos SET status_complete=? WHERE id=?", [status_complete, id])
        redirect("/todos")
    end

    get '/todos/:id/edit' do |id|

        authenticated()

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

        authenticated()

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


    get '/register' do
        erb(:"register")
    end

    post '/register' do
        username = params['username']
        cleartext_password = params['password'] 
        hashed_password = BCrypt::Password.create(cleartext_password)
        p hashed_password
        db.execute('INSERT INTO users (username, password) VALUES(?,?)', [username, hashed_password.to_s])

        user = db.execute('SELECT id FROM users WHERE username =?', username).first

        p "session i guess"
        session[:user_id] = user['id'] 
        p session[:user_id]
        redirect("/todos")
    end


    get '/login' do
        erb(:"login")
    end

    post '/login' do
        username = params['username']
        cleartext_password = params['password'] 
      

        user = db.execute('SELECT * FROM users WHERE username = ?', username).first

        if !user
            redirect("/login_error")

        end
      

        password_from_db = BCrypt::Password.new(user['password'])

        if password_from_db == cleartext_password 
            session[:user_id] = user['id'] 
            redirect("/todos")
        else
            redirect("/login_error")

        end
      
    end

    get '/login_error' do 
        erb(:"login_error")
    end

    get '/logout' do 
        session.destroy
        redirect("/user")
    end

    get '/user' do 
        erb(:"user")
    end


end