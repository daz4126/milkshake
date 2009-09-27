class Snippet
  include DataMapper::Resource
# Properties
  property :name,         String,   :key => true
  property :content,      Text,      :default => "Enter some content here"
end

# Snippet routes

#index
get '/snippets' do
  protected!
  @snippets = Snippet.all
  erb :'milkshake/snippet_index',:layout=>:'milkshake/layout'
end

#new
get '/new/snippet' do
  protected!
  @snippet = Snippet.new
  erb :'milkshake/snippet_new',:layout=>:'milkshake/layout'
end

#create
post '/new/snippet' do
  protected!
  @snippet = Snippet.new(params[:snippet])
  if @snippet.save
    status 201
    redirect '/snippets'
  else
    status 412
    redirect '/new/snippet'   
  end
end

#edit
get '/snippets/:name' do
  protected!
  @snippet = Snippet.get(params[:name])
  erb :'milkshake/snippet_edit',:layout=>:'milkshake/layout'
end

#update
put '/snippets/:name' do
  protected!
  @snippet = Snippet.get!(params[:name])
  if @snippet.update_attributes(params[:snippet])
    status 201
    redirect '/snippets'
  else
    status 412
    redirect '/snippets/#{@snippet.name}'   
  end
end

# delete
delete '/snippets/:name' do
  protected!
  @snippet = Snippet.get!(params[:name])
  @snippet.destroy
  redirect '/snippets'  
end

