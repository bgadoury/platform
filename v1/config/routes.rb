V1::Engine.routes.draw do
  # All these routes are relative to this engine's mount point defined in the main app
  # E.g. if this engine is mounted at "/api/v1", then 'get "/search"' in this routes.rb
  # would match "/api/v1/search"

  # ITEMS
  #NOTE: We cannot use the defaults->format block until the format field has been renamed in the schema
  #get "/items(.:format)" => "search#items", :as => :items, :defaults => { :format => 'json' }
  get "/items" => "search#items"  #original, WORKS
#  get "/items(.:format)" => "search#items"  #original + :format, WORKS
#  get "/items" => "search#items", :as => :items  #original + :format + :as, WORKS

  get "/items/links" => "search#links"
  get "/items(.:format)/*ids" => "search#fetch", :as => :items_fetch  #, :defaults => { :format => 'json' }


  # COLLECTIONS
  get "/collections" => "search#collections"
  get "/collections(.:format)/*ids" => "search#fetch_collections", :as => :collections_fetch

  get "/repo/status" => "search#repo_status"

end
