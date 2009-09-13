require 'maruku'

class Page
  include DataMapper::Resource
# Properties
  property :id,           Serial
  property :title,        String,   :nullable => false, :default => "Title"
  property :permalink,    String,  :default => Proc.new { |r, p| r.slug }
  property :content,      Text, :default => "Enter some content here"
  property :created_at, DateTime#, :default => Time.now
  property :updated_at, DateTime
  property :published_at, DateTime, :default => nil
  property :position,     Integer, :default => Proc.new { |r, p| r.siblings.empty? ?  1 : r.siblings.size.next }
  property :parent_id,    Integer, :default => nil
  property :show_title,   Boolean, :default => true
  
# Callbacks  
  before :save do
    old_permalink = self.permalink
    new_permalink = self.parent_id ?  self.parent.permalink + "/" + self.slug : self.slug
    if new_permalink != old_permalink
      self.permalink = new_permalink
      @new_permalink = true
    end
  end
  
  after :save do
    if @new_permalink && self.children?
      self.children.each { |child| child.save }
      @new_permalink = false
    end
  end
  
# Validations
  validates_is_unique :permalink


# Default order
  default_scope(:default).update(:order => [:position]) 

# Associations 
  belongs_to  :parent,    :class_name => "Page",   :child_key => [:parent_id]
  has n,      :children,  :class_name => "Page",   :child_key => [:parent_id]

 
# Some named_scopes
def self.published
  all(:published_at.not => nil)
end

def self.roots
  all(:parent_id => nil)
end

def self.recent(number=1)
  all(:order => [:created_at.desc], :limit => number)
end

def self.random(number=1)
  #not currently working - now way to get random records in dm
  #all(:order => ['RAND()'], :limit => number)
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
  Page.all(:parent_id => self.parent_id)
end

def siblings
  Page.all(:parent_id => self.parent_id,:id.not => self.id)
end

# Returns a page's permalink based on its title
def slug
  title.downcase.gsub(/\W/,'-').squeeze('-').chomp('-')
end

# Returns a summary of the page
def summary
  text = self.content[0,400]
end

#useful paths for the page
def path
  "/" + self.permalink
end

def edit_path
  "/page/" + self.id.to_s
end

def delete_path
  "/page/#{self.id}/delete"
end

def new_path
  "/new/page"
end

def new_child_path
  "/new/page?section=" + self.id.to_s
end

def new_sibling_path
  "/new/page?section=" + self.parent_id.to_s
end

#test if a page is a root page
def root?
  parent_id == nil
end

#test if a page is published or not
def published?
  true unless published_at.nil?
end

#test if a page is a draft or not
def draft?
  published_at.nil?
end

#test if a page has children or not
def children?
  !self.children.empty?
end
 
end

# Page routes

# Show home page
get '/' do
  @page = Page.roots.published.first
  if @page
    erb :'milkshake/show',:layout=>:'milkshake/layout'
  else
    redirect '/pages'
  end    
end

#admin dashboard/index
get '/pages' do
  @pages = admin? ? Page.roots: Page.roots.published
  erb :'milkshake/index',:layout=>:'milkshake/layout'
end

#new
get '/new/page' do
  authorise
  @page = Page.new(:parent_id => params[:section])
  erb :'milkshake/new',:layout=>:'milkshake/layout'
end

#create
post '/new/page' do
  authorise
  @page = Page.new(params[:page])
  @page.show_title = false unless params[:show_title]
  @page.published_at = params[:publish] ?  Time.now : nil
  if @page.save
    status 201
    redirect @page.path
  else
    status 412
    redirect '/pages'   
  end
end

#edit
get '/page/:id' do
  authorise
  @page = Page.get(params[:id])
  if @page
    erb :'milkshake/edit',:layout=>:'milkshake/layout'
  else
    redirect '/pages'
  end
end

#update
put '/page/:id' do
  authorise
  @page = Page.get(params[:id])
  @page.show_title = false unless params[:show_title]
  @page.published_at = params[:publish] ?  Time.now : nil
  if @page.update_attributes(params[:page])
    status 201
    redirect @page.path
  else
    status 412
    redirect '/pages'   
  end
end

# delete confirmation
get '/page/:id/delete' do
  authorise
  @page = Page.get!(params[:id])
  erb :'milkshake/delete',:layout=>:'milkshake/layout'
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
  @page = Page.first(:permalink => params[:splat])
  raise error(404) unless @page
  authorise if @page.draft?
  erb :'milkshake/show',:layout=>:'milkshake/layout'
end

# errors
error 404 do
  erb :'milkshake/page_missing',:layout=>:'milkshake/layout'
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

def css(*stylesheets)
  stylesheets.inject([]) do |html,stylesheet|
    html << "<link rel=\"stylesheet\" type=\"text/css\" media=\"screen, projection\" href=\"/stylesheets/#{stylesheet.to_s}.css\" />"
   end.join("\n")
end

def js(*scripts)
  scripts.inject([]) do |html,script|
    html << "<script src=\"#{script}.js\" type=\"text/javascript\"></script>"
   end.join("\n")
end

def breadcrumbs(page=@page,separator=">>")
  pages = page.ancestors.reverse + [page]
  separator = " " + separator + " "
  pages.inject("<div class=\"breadcrumbs\">") do |list,crumb|
    list << "<a href=\"#{crumb.path}\">#{crumb.title}</a>" + separator
  end.chomp(separator).concat("</div>")
end

def list_of_links(pages=:roots,opts={})
  pages = @page.respond_to?(pages.to_sym) ? @page.send(pages.to_sym).published : Page.published.roots
  attributes = ""
  opts.each { |key,value| attributes << key.to_s << "=\"" << value << "\" "}
  output = "<ul #{attributes}>"
  pages.each{ |page| output << "\n<li><a href=\"#{page.path}\">#{page.title}</a></li>"}
  output << "\n</ul>"
end

def shakedown(text)
  text.gsub!(/(?:%\s*)(\w+)(?:\s*[(\r\n)%])/) do |match|
    if @page && @page.respond_to?($1.to_sym)
      @page.send($1.to_sym).to_s
    else
      match
    end
  end
  text.gsub!(/(%)(=)?(\s*)(.*)(%)/,'<%\2 \4 %>')
  text = erb(text,:layout => false)
  Maruku.new(text).to_html
end
 
end


