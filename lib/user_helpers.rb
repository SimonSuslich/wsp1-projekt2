def user_authenticated
  if !session[:user_id] 
    redirect("/log_in")
  end
end

def get_user_by_name(username)
  db.execute('SELECT * FROM users WHERE username = ?', username).first
end

def get_user_by_email(email)
  db.execute('SELECT * FROM users WHERE user_email = ?', email).first
end

def check_username(username)
  username_list = db.execute("SELECT username FROM users WHERE username=?", username)

  if !username_list.empty?
    redirect("/error")
  end
end

def new_user(user_info)
  db.execute("INSERT INTO users (username, user_email, password) 
  VALUES (?, ?, ?)
  ", user_info)
end