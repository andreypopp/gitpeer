require 'gitpeer/controller'

class GitPeer::Wiki < GitPeer::Controller
  uri :wiki_page,         '/{+page}'
  uri :wiki_page_history, '/{+page}/history'

  get :wiki_page
  get :wiki_page_history

  put :wiki_page
  delete :wiki_page
end
