# Controlers go in here

# Show home page
get '/' do
  @page = Page.roots.first
  erb :show
end

#admin dashboard/indedx
get '/admin' do
  @pages = Page.roots
  erb :admin
end

#new
get '/new/page' do
  @page = Page.new
  @page.parent_id = params[:parent]
  erb :new
end

#create
post '/create/page' do
  @page = Page.new(params[:page])
  @page.show_title = false unless params[:show_title]
  @page.published_on = Time.now if params[:publish]
  if @page.save
    status 201
    redirect @page.url
  else
    status 412
    redirect '/admin'   
  end
end

#edit
get '/page/:id' do
  @page = Page.get!(params[:id])
  if @page
    erb :edit
  else
    redirect '/admin'
  end
end

#update
put '/page/:id' do
  @page = Page.get!(params[:id])
  @page.show_title = false unless params[:show_title]
  @page.published_on = params[:publish] ?  Time.now : nil
  if @page.update_attributes(params[:page])
    status 201
    redirect @page.url
  else
    status 412
    redirect '/admin'   
  end
end

#delete confirmation
get '/page/:id/confirm-delete' do
  @page = Page.get!(params[:id])
  erb :delete
end

#delete
delete '/page/:id' do
  @page = Page.get!(params[:id])
  @page.destroy
  redirect '/admin'  
end

#show - should come last in order
get '/*' do
  @page = Page.first(:path => params[:splat])
  raise error(404) unless @page
  erb :show
end

error 404 do
  erb :page_missing
end

