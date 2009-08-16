# Controlers go in here

get '/' do
  @pages = Page.all
  erb :index
end

#create
post '/create/page' do
  @page = Page.new(:title => params[:title],:parent_id => 1)
  if @page.save
    status 201
    redirect "/page/" + @page.id.to_s
  else
    status 412
    redirect '/'   
  end
end

#update
put '/page/:id' do
  @page = Page.get(params[:id])
  if @page.save
    status 201
    redirect "/"
  else
    status 412
    redirect '/'   
  end
end

#show
get '/page/:id' do
  @page = Page.get(params[:id])
  if @page
    erb :show
  else
    redirect '/'
  end
end

#show
get '/*' do
  #@page = Page.get(params[:splat])
 #if @page
    erb :show
  #else
    #redirect '/'
  #end
end
