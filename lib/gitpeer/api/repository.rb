require 'rugged'
require 'gitpeer/controller'
require 'gitpeer/controller/json_representation'
require 'gitpeer/controller/uri_templates'

module GitPeer::API
  class Repository < GitPeer::Controller
    include GitPeer::Controller::JSONRepresentation
    include GitPeer::Controller::URITemplates

    uri :repository,    '/'
    uri :branch,        '/branch/{id}'
    uri :tag,           '/tag/{id}'
    uri :commit,        '/commit/{id}'
    uri :tree,          '/tree/{id}'
    uri :blob,          '/blob/{id}'
    uri :object,        '/{id}'
    uri :contents,      '/contents/{ref}{+path}'
    uri :history,       '/history/{ref}{?limit,after}'
    uri :path_history,  '/history/{ref}/{+path}{?limit,after}'

    Contents = Struct.new(:path, :ref, :commit, :blob, :tree)
    History = Struct.new(:ref, :limit, :after, :commits, :next_id, :prev_id)
    Repository = Struct.new(:name, :description, :ref)

    get :repository do
      json repository
    end

    get :contents do
      path = param :path, default: ''
      ref_name = param :ref

      ref = or_404 { ref_by_name(ref_name) }
      commit = or_404 { git.lookup(ref.resolve.target) }

      obj = if path == ''
        commit.tree
      else
        entry = or_404 { commit.tree.path(path[1..-1]) }
        git.lookup(entry[:oid])
      end

      tree = obj.is_a?(Rugged::Tree) ? obj : nil
      blob = obj.is_a?(Rugged::Blob) ? obj : nil

      json Contents.new(path, ref_name, commit, blob, tree)
    end

    get :history do
      ref_name = param :ref
      after = param :after
      limit = param :limit, type: Integer, default: 50


      ref = or_404 { ref_by_name(ref_name) }
      commits = walk_from(after || ref.target).take(limit).to_a
      next_id = commits.last.parents.first.oid if commits.last.parents.first
      prev_id = prev_to_commit(ref_name, commits.first.oid, limit)
      json History.new(ref_name, limit, after, commits, next_id, prev_id)
    end

    get :path_history

    [:branch, :tag, :commit, :tree, :blob, :object].each do |type|
      get type do
        obj = or_404 { git.lookup(param :id) }
        not_found unless type == :object or obj.type == type
        json obj
      end
    end

    representation Repository do
      prop :name
      prop :description
      prop :ref
      link :self,     template: uri(:repository)
      link :history,  template: uri(:history)
      link :contents, template: uri(:contents)
    end

    class BasicCommitRepresentation < Representation
      prop :id, from: :oid
      prop :message
      prop :author
      prop :committer
      prop :tree_id
      link :self,     template: uri(:commit)
      link :tree,     template: uri(:tree)
      link :contents, template: uri(:contents)
    end

    class CommitRepresentation < BasicCommitRepresentation
      collection :diff,
        from: proc { obj.diff(reverse: true) },
        repr: Rugged::Diff::Patch
    end

    representation Rugged::Commit, CommitRepresentation
    representation Rugged::Commit, BasicCommitRepresentation, name: :basic

    representation Contents do
      prop :path
      prop :ref
      prop :commit, repr: Rugged::Commit, repr_name: :basic
      prop :blob, repr: Rugged::Blob
      prop :tree, repr: Rugged::Tree
      link :self, template: uri(:contents)
      link :entry_contents, templated: true do
        "#{uri(:contents, ref: obj.ref, path: obj.path)}/{+path}"
      end
    end

    representation History do
      prop :ref
      prop :limit
      prop :after
      collection :commits, repr: Rugged::Commit, repr_name: :basic
      link :self do
        uri :history, ref: obj.ref, limit: obj.limit, after: obj.after
      end
      link :next do
        uri :history, ref: obj.ref, limit: obj.limit, after: obj.next_id if obj.next_id
      end
      link :prev do
        uri :history, ref: obj.ref, limit: obj.limit, after: obj.prev_id if obj.prev_id
      end
    end

    representation Rugged::Blob do
      prop :id, from: :oid
      prop :content
      link :self, template: uri(:blob)
    end

    representation Rugged::Tree do
      prop :id, from: :oid
      collection :entries do
        value :id, from: :oid
        value :type
        value :name
        link :self do
          uri obj[:type], id: obj[:oid]
        end
      end
      link :self, template: uri(:tree)
    end

    representation Rugged::Diff::Patch do
      prop :delta, repr: Rugged::Diff::Delta
      prop :size
      prop :additions
      prop :deletions
      prop :deletions
      collection :hunks, repr: Rugged::Diff::Hunk
    end

    representation Rugged::Diff::Delta do
      prop :old_file
      prop :new_file
      prop :similarity
      prop :status
      prop :binary
    end

    representation Rugged::Diff::Hunk do
      prop :size
      prop :header
      prop :range
      collection :lines, repr: Rugged::Diff::Line
    end

    representation Rugged::Diff::Line do
      prop :line_origin
      prop :content
      prop :old_lineno
      prop :new_lineno
    end

    protected

      def self.repository
        name = File.basename File.absolute_path config[:repo_path]
        Repository.new(name, config[:description], config[:ref] || 'master')
      end

      def self.git
        Rugged::Repository.new("#{config[:repo_path]}/.git")
      end

      def prev_to_commit(ref_name, sha, limit)
        filename = "#{config[:repo_path]}/.git/logs/refs/heads/#{ref_name}"
        commits = File.open(filename)
          .map { |line| line.split(' ')[0..1] }
          .drop_while { |shas| shas[0] != sha }
        commits = commits[0..limit + 1]
        commits.empty? ? nil : commits.last.last
      end

      def branch_by_name(name)
        git.ref("refs/heads/#{name}")
      end

      def tag_by_name(name)
        git.ref("refs/tags/#{name}")
      end

      def ref_by_name(name)
        branch_by_name(name) || tag_by_name(name)
      end

      def walk_from(from_id)
        walker = Rugged::Walker.new(git)
        walker.sorting(Rugged::SORT_TOPO)
        walker.push(from_id)
        walker
      end

      def or_404
        result = begin
          yield
        rescue Rugged::OdbError
          nil
        rescue Rugged::InvalidError
          nil
        rescue Rugged::ObjectError
          nil
        rescue Rugged::TreeError
          nil
        end
        not_found if result == nil
        result
      end
  end
end
