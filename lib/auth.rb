enable :sessions 

#admin login page
get '/login' do
  erb :'milkshake/login',:layout=>:'milkshake/layout'
end

post '/login' do
  if params[:user][:name] == USER_NAME && params[:user][:password] == PASSWORD
    session[:user] = USER_NAME
  end
  redirect '/pages'
end

#admin logout page
get '/logout' do
  session[:user] = false
  redirect '/pages'
end

helpers do
def admin?
  session[:user]
end
 
def protected!
  stop [ 401, 'You do not have permission to see this page.' ] unless admin?
end
end
