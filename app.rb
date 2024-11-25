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
        @not_completed_todos = db.execute('SELECT * FROM todos WHERE status_complete = false ORDER BY id')
        @completed_todos = db.execute('SELECT * FROM todos WHERE status_complete = true ORDER BY id')
        erb(:"index")
    end

    post '/todos' do 
        title = params['title']
        description = params['description']
        # category = params['category']
        due_date = params['due_date']
        db.execute("INSERT INTO todos (title, description, due_date, post_date) VALUES(?,?,?, DATE('now'))", [title, description, due_date])
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

    # # Övning no. 2.1
    # # Routen visar ett formulär för att spara en ny frukt till databasen.
    # get '/fruits/new' do 
    #     erb(:"fruits/new")
    # end

    # # Övning no. 2.2
    # # Routen sparar en frukt till databasen och gör en redirect till '/fruits'.
    # post '/fruits' do 
    #     p params
    #     #todo
    # end

    # # Övning no. 1
    # # Routen visar en frukt.
    # get '/fruits/:id_num' do | id_num |
      
    #     @fruit = db.execute('SELECT * FROM fruits WHERE id=?', id_num).first
   
    #     erb(:"fruits/show")
    # end






    get '/todos/:id/edit' do |id|
        @todo = db.execute('SELECT * FROM todos WHERE id=?', id).first
        erb(:"edit")
    end
        

    post '/todos/:id/update' do |id|

        title = params['title']
        description = params['description']
        # category = params['category']
        due_date = params['due_date']

        
        db.execute("UPDATE todos SET title=?, description=?, due_date=?, post_date=DATE('now') WHERE id=?", [[title, description, due_date], id])
        redirect("/")

    end



end