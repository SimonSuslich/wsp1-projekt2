def user_authenticated
  if !session[:user_id] 
    redirect("/log_in")
  end
end

def check_username(username)
  username_list = db.execute("SELECT username FROM users WHERE username=?", username)

  if !username_list.empty?
    redirect("/error")
  end
end