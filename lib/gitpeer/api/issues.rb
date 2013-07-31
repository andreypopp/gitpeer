require 'json'
require 'date'
require 'digest/sha1'
require 'gitpeer/controller'
require 'gitpeer/controller/json_representation'

module GitPeer::API
  class Issues < GitPeer::Controller
    include GitPeer::Controller::JSONRepresentation

    uri :issues,  '/'
    uri :issue,   '/{id}'

    get :issues do
      state = param :state, default: 'opened'

      issues = db.execute "select * from issues where state = ?", state
      issues = issues.map { |row| Issue.new(*row) }
      json Issues.new(issues.to_a)
    end

    post :issues do
      # XXX: doesn't work but should
      # issue = representation(Issue).from_json(request.body.read)

      now = DateTime.now.to_s
      issue = JSON.parse request.body.read, symbolize_names: true
      issue = Issue.new(generate_id, issue[:name], issue[:body], OPENED, now, now)
      db.execute "
        insert into issues(id, name, body, state, created, updated)
        values(?, ?, ?, ?, ?, ?)", *issue.to_a
      puts issue
      json({a: 1})
    end

    get :issue do
      id = captures[:id]
      issue = db.execute("select * from issues where id = ?", id).first
      not_found unless issue
      json Issue.new(*issue)
    end

    patch :issue do
    end

    delete :issue do
      id = captures[:id]
      issue = db.execute "select * from issues where id = ?", id
      db.execute "delete * from issues where id = ?", id
      not_found unless issue
      json Issue.new(*issue)
    end

    Issues = Struct.new(:issues)
    # possible state values: opened, closed
    Issue = Struct.new(:id, :name, :body, :state, :created, :updated)
    OPENED = 'opened'
    CLOSED = 'closed'

    representation Issues do
      collection :issues, resolve: true
      link :self do
        uri :issues
      end
    end

    representation Issue do
      property :id
      property :name
      property :body
      property :state
      property :created
      property :updated
      link :self do
        uri :issue, id: represented.id
      end
    end

    def generate_id
      srand
      seed = "--#{rand(10000)}--#{Time.now}--"
      Digest::SHA1.hexdigest(seed)
    end

    def self.db
      config[:db]
    end

    def self.configured
      db.execute "
        create table if not exists issues(
          id text,
          name text,
          body text,
          state text,
          created text,
          updated text
        );
        "
    end

  end
end
