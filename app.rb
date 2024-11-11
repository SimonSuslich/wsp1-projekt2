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
        category = params['category']
        due_date = params['due_date']
        
        db.execute("INSERT INTO todos (title, description, category, due_date, post_date) VALUES(?,?,?,?,?)", [title, description, category, due_date, "CURRENT_TIMESTAMP"])
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

    # post '/fruits/:id/delete' do | id |
    #     #todo: ta bort frukten med idt
    #     db.execute('DELETE FROM fruits WHERE id = ?', id)
    #     redirect("/fruits")        
    # end




    # get '/fruits/:id/edit' do |id|
    #     @fruit = db.execute('SELECT * FROM fruits WHERE id=?', id).first
    #     erb(:"fruits/edit")
    # end
        

    # post '/fruits/:id/update' do |id|


    #     name = params['name']
    #     tastiness = params['tastiness']
    #     description = params['description']
        
    #     db.execute("UPDATE fruits SET name=?, description=?, tastiness=? WHERE id=?", [[name, tastiness, description], id])
    #     redirect("/fruits")

    # end



end