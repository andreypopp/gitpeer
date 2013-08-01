require 'json'
require 'date'
require 'sequel'
require 'digest/sha1'
require 'gitpeer/controller'
require 'gitpeer/controller/json_representation'

class Sequel::Dataset

  def as(cls)
    to_a.map do |row|
      values = cls.members.map { |k| row[k] }
      cls.new(*values)
    end
  end
end

module GitPeer::API
  class Issues < GitPeer::Controller
    include GitPeer::Controller::JSONRepresentation

    uri :issues,  '/{?state}'
    uri :issue,   '/{id}'

    get :issues do
      state = param :state, default: 'opened'
      issues = db[:issues].where(:state => state).as(Issue)
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
      values = body.select { |k, v| [:name, :body].contains k }
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

    Issue = Struct.new(:id, :name, :body, :state, :created, :updated)
    Issues = Struct.new(:issues, :stats)

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

    def body_as(cls)
      representation(cls).new(cls.new).from_json(request.body.read)
    end

    def body
      JSON.parse request.body.read, symbolize_names: true
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
