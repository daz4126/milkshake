class Page
  include DataMapper::Resource
# Properties
  property :id,           Serial
  property :title,        String,   :nullable => false
  property :path,    String,   :default => Proc.new { |r, p| r.parent_id ?  r.parent.path + "/" + r.permalink : r.permalink }
  property :content,      Text
  property :published_on, DateTime, :default => nil
  property :position,     Integer, :default => Proc.new { |r, p| r.siblings.empty? ?  1 : r.siblings.last.position.next }
  property :parent_id,    Integer, :default => nil
  property :show_title,   Boolean, :default => true

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
  title.downcase.gsub(/\W/, '-').gsub(/\-+/, '-')
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
 



end


