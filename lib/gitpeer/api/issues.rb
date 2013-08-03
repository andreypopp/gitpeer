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

    uri :issues,       '/{?state}'
    uri :issues_tags,  '/tags'
    uri :issue,        '/{id}'

    Issue = Struct.new(:id, :name, :body, :state, :created, :updated, :tags)
    Issues = Struct.new(:issues, :stats, :state)

    get :issues do
      state = param :state, default: 'opened'
      issues = db[:issues].where(:state => state).reverse(:updated).as(Issue)
      stats = db[:issues].group_and_count(:state).to_hash(:state, :count)
      json Issues.new(issues, stats, state)
    end

    post :issues do
      now = DateTime.now
      issue = body_as Issue
      issue.state = 'opened'
      issue.created = now
      issue.updated = now
      issue.id = db.transaction do
        issue_id = db[:issues].insert_from issue
        if issue.tags
          tags = issue.tags.map { |t| {tag: t, issue_id: issue_id} }
          db[:issue_tags].multi_insert tags
        end
        issue_id
      end
      json(issue)
    end

    get :issues_tags do
      json db[:issue_tags].group_and_count(:tag).to_hash(:tag, :count)
    end

    get :issue do
      id = captures[:id]
      issue = db[:issues].where(id: id).as(Issue).first
      not_found unless issue
      issue.tags = db[:issue_tags].where(issue_id: id).single_row(:tag)
      json issue
    end

    patch :issue do
      id = captures[:id]
      issue = db[:issues].where(id: id).as(Issue).first
      not_found unless issue
      values = body.select { |k, v| [:name, :body, :state].include? k }
      unless values.empty?
        values[:updated] = DateTime.now
        db[:issues].where(id: id).update(**values)
        values.each { |k, v| issue[k] = v }
      end
      json issue
    end

    # XXX: Add link/unlink method to Scorched
    route :issue, method: ['LINK'] do
      id = captures[:id]
      tag = param :tag
      db[:issue_tags].insert(issue_id: id, tag: tag)
    end

    route :issue, method: ['UNLINK'] do
      id = captures[:id]
      tag = param :tag
      db[:issue_tags].where(issue_id: id, tag: tag).delete
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
      property :state
      collection :issues, resolve: true
      link :self do
        uri :issues, state: represented.state
      end
      link rel: :filtered, templated: true do
        "#{uri :issues}{?state}"
      end
    end

    representation Issue do
      property :id
      property :name
      property :body
      property :state
      property :created
      property :updated
      property :tags
      link :self do
        uri :issue, id: represented.id
      end
    end

    def self.db
      config[:db]
    end

    def self.configured

      db.transaction do
        db["create table if not exists issue_tags(
            issue_id int,
            tag text,
            primary key (issue_id, tag)
          );"].all

        db["create table if not exists issues(
            id integer primary key autoincrement,
            name text,
            body text,
            state text,
            created text,
            updated text
          );"].all

      end
    end

  end
end
