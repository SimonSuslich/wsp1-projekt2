def get_user(user_name_email)
  user = db.execute('SELECT * FROM users WHERE username = ? OR user_email = ?', [user_name_email, user_name_email]).first
  return user if user
  halt erb(:error, locals: { message: "Invalid credentials", status: 401, route: "/log_in" })
end

def check_username_and_email(username, user_email)
  user_list = db.execute("SELECT username FROM users WHERE username=? OR user_email=?", [username, user_email])

  if !user_list.empty?
    halt erb(:error, locals: { message: "Username or email already in use", status: 400, route: "/sign_up" })
  end
end

def new_user(user_info)
  db.execute("INSERT INTO users (username, user_email, password) 
  VALUES (?, ?, ?)
  ", user_info)
end