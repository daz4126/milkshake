class Page
  include DataMapper::Resource
# Properties
  property :id,           Serial
  property :title,        String,   :nullable => false, :default => "Title"
  property :path,         String,  :default => Proc.new { |r, p| r.permalink }
  property :content,      Text, :default => "Enter some content here"
  property :published_on, DateTime, :default => nil
  property :position,     Integer, :default => Proc.new { |r, p| r.siblings.empty? ?  1 : r.siblings.size.next }
  property :parent_id,    Integer, :default => nil
  property :show_title,   Boolean, :default => true
  
# Callbacks  
  before :save do
    old_path = self.path
    new_path = self.parent_id ?  self.parent.path + "/" + self.permalink : self.permalink
    if new_path != old_path
      self.path = new_path
      @new_path = true
    end
  end
  
  after :save do
    if @new_path && self.children?
      self.children.each { |child| child.save }
      @new_path = false
    end
  end
  
# Validations
  validates_is_unique :path


# Default order
  default_scope(:default).update(:order => [:position]) 

# Associations 
  belongs_to  :parent,    :class_name => "Page",   :child_key => [:parent_id]
  has n,      :children,  :class_name => "Page",   :child_key => [:parent_id]

 
# Some named_scopes
def self.published
  all(:published_on.not => nil)
end

def self.roots
  all(:parent_id => nil)
end

#returns the level of the page, 1 = root
def level
  level,page = 1, self
  level,page = level.next, page.parent while page.parent
  level
end

def ancestors
  page, pages = self, []
  pages << page = page.parent while page.parent
  pages
end

# Returns the root node of the tree.
def root
  page = self
  page = page.parent while page.parent
  page
end

def self_and_siblings
  parent ? parent.children : Page.roots
end

def siblings
  self_and_siblings - [ self ]
end

# Returns a page's permalink based on its title
def permalink
  title.downcase.gsub(/\W/,'-').squeeze('-')
end

def url
  "/" + self.path
end

#test if a page is a root page
def root?
  parent_id == nil
end

#test if a page is published or not
def published?
  true unless published_on.nil?
end

#test if a page is a draft or not
def draft?
  published_on.nil?
end

#test if a page has children or not
def children?
  !self.children.empty?
end
 
end

# Page routes

# Show home page
get '/' do
  @page = Page.roots.published
  if @page
    erb :show
  else
    redirect '/pages'
  end    
end

#admin login
get '/login' do
  erb :login
end

post '/login' do
  session[:admin] = true
  redirect '/pages'
end

#admin logout
get '/logout' do
  session[:admin] = false
  redirect '/pages'
end

#admin dashboard/index
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



helpers do
def page_title
  if @title
    SITE_NAME + " * " + @title
  elsif @page
    SITE_NAME + " * " + @page.title
  else
    SITE_NAME
  end 
end
    
def navmenu(pages=:roots,clas=nil)
  pages = @page.respond_to?(pages.to_sym) ? @page.send(pages.to_sym) : Page.published.roots
  output = "<ul"
  clas ? output << " class=\"" + clas + "\">" : output << ">"
  pages.each{ |page| output << "\n<li><a href=\"#{page.url}\">#{page.title}</a></li>"}
  output << "\n</ul>"
end 

def shakedown(text)
  # allows access to pages properties eg {= title }
  text.gsub!(/(?:%\s*)(\w+)(?:\s*%)/) do |match|
    if @page && @page.respond_to?($1.to_sym)
      @page.send($1.to_sym).to_s
    else
      match
    end
  end
  # allows access to helper methods eg %= navmenu
  text.gsub!(/(?:%=\s*)(\w+)(?:\s*)(?:\(([\w,\,]+)\))?/) do |match|
    if $1 && $2 && respond_to?($1.to_sym,$2)
      send($1.to_sym,$2)
    elsif $1 && respond_to?($1.to_sym)
      send($1.to_sym)
    else
      match 
    end
  end
  Maruku.new(text).to_html.gsub('h1>','h3>').gsub('h2>','h4>')
end
 
end


