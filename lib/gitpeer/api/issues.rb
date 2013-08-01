require 'json'
require 'date'
require 'sequel'
require 'sequel/extensions'
require 'digest/sha1'
require 'gitpeer/controller'
require 'gitpeer/controller/json_representation'

module GitPeer::API
  class Issues < GitPeer::Controller
    include GitPeer::Controller::JSONRepresentation

    uri :issues,  '/{?state}'
    uri :issue,   '/{id}'

    Issue = Struct.new(:id, :name, :body, :state, :created, :updated)
    Issues = Struct.new(:issues, :stats)

    get :issues do
      state = param :state, default: 'opened'
      issues = db[:issues].where(:state => state).reverse(:updated).as(Issue)
      stats = db[:issues].group_and_count(:state).to_hash(:state, :count)
      json Issues.new(issues, stats)
    end

    post :issues do
      now = DateTime.now
      issue = body_as Issue
      issue.id = generate_id
      issue.state = 'opened'
      issue.created = now
      issue.updated = now
      db[:issues].insert(issue.to_h)
      json(issue)
    end

    get :issue do
      id = captures[:id]
      issue = db[:issues].where(:id => id).as(Issue).first
      not_found unless issue
      json issue
    end

    patch :issue do
      id = captures[:id]
      issue = db[:issues].where(id: id).as(Issue).first
      not_found unless issue
      values = body.select { |k, v| [:name, :body, :state].include? k }
      unless values.empty?
        db[:issues].where(id: id).update(**values)
        values.each { |k, v| issue[k] = v }
      end
      json issue
    end

    delete :issue do
      id = captures[:id]
      id = captures[:id]
      issue = db[:issues].where(:id => id).as(Issue).first
      not_found unless issue
      db[:issues].where(:id => id).delete
      json issue
    end

    representation Issues do
      property :stats
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
      db["create table if not exists issues(
          id text primary key,
          name text,
          body text,
          state text,
          created text,
          updated text
        );
      "]
    end

  end
end
