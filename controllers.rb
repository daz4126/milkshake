# Controlers go in here

# Show home page
get '/' do
  @page = Page.roots.published
  if @page
    erb :show
  else
    redirect '/pages'
  end    
end

#admin dashboard/indedx
get '/pages' do
  @pages = admin? ? Page.roots: Page.roots.published
  erb :index
end

#edit
['/page/:id', '/new/page'].each do |path|
get path do
  authorise
  @page = Page.get(params[:id]) || Page.new(:parent_id => params[:parent])
  if @page
    erb :edit
  else
    redirect '/pages'
  end
end
end

#update
['/page/:id', '/page/'].each do |path|
put path do
  authorise
  @page = Page.get(params[:id]) || Page.new(params[:page])
  @page.show_title = false unless params[:show_title]
  @page.published_on = params[:publish] ?  Time.now : nil
  if @page.update_attributes(params[:page])
    status 201
    redirect @page.url
  else
    status 412
    redirect '/pages'   
  end
end
end

# delete confirmation
get '/page/:id/delete' do
  authorise
  @page = Page.get!(params[:id])
  erb :delete
end

# delete
delete '/page/:id' do
  authorise
  @page = Page.get!(params[:id])
  @page.destroy
  redirect '/pages'  
end

# show - should come last in order
get '/*' do
  @page = Page.first(:path => params[:splat])
  authorise if @page.draft?
  raise error(404) unless @page
  erb :show
end

# errors
error 404 do
  erb :page_missing
end

