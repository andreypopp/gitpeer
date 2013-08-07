require 'gitpeer/controller'
require 'gitpeer/controller/json_representation'
require 'gitpeer/controller/uri_templates'

class GitPeer::Wiki < GitPeer::Controller
  include GitPeer::Controller::JSONRepresentation
  include GitPeer::Controller::URITemplates

  uri :wiki_page,         '/{+page}'
  uri :wiki_page_history, '/{+page}/history'

  get :wiki_page
  get :wiki_page_history

  put :wiki_page
  delete :wiki_page
end
