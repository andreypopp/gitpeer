require 'rugged'
require 'gitpeer/controller'
require 'gitpeer/controller/json_representation'

module GitPeer::API
  class Repository < GitPeer::Controller
    include GitPeer::Controller::JSONRepresentation

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
      limit = param :limit, type: Integer, default: 30

      ref = or_404 { ref_by_name(ref_name) }
      commits = walk_from(after || ref.target).take(limit).to_a
      json History.new(ref_name, limit, after, commits)
    end

    get :path_history

    [:branch, :tag, :commit, :tree, :blob, :object].each do |type|
      get type do
        obj = or_404 { git.lookup(param :id) }
        not_found unless type == :object or obj.type == type
        json obj
      end
    end

    Contents = Struct.new(:path, :ref, :commit, :blob, :tree)
    History = Struct.new(:ref, :limit, :after, :commits)
    Repository = Struct.new(:name, :description, :default_branch)

    class TreeEntryRepresentation < Representation
      value :oid, as: :id
      value :type
      value :name
      link :self do uri represented[:type], id: represented[:oid] end
    end

    register_representation Repository do
      property :name
      property :description
      property :default_branch

      link :self do
        uri :repository
      end
      link :history do
        uri :history, ref: represented.default_branch
      end
      link :contents do
        uri :contents, ref: represented.default_branch
      end
    end

    register_representation Contents do
      property :path
      property :ref
      property :commit, resolve: true, name: :basic
      property :blob, resolve: true
      property :tree, resolve: true
      link :self do
        uri :contents,
          ref: represented.ref,
          path: represented.path
      end
      # XXX: It would be nice to have URITemplate#partial_expand instead
      link :rel => :entry_contents, :templated => true do
        prefix = uri :contents, ref: represented.ref
        "#{prefix}{+path}"
      end
    end

    register_representation History do
      property :ref
      property :limit
      property :after
      collection :commits, resolve: true, name: :basic
      link :self do
        uri :history,
          ref: represented.ref,
          limit: represented.limit,
          after: represented.after
      end
    end

    class BasicCommitRepresentation < Representation
      property :oid, as: :id
      property :message
      property :author
      property :committer
      property :tree_id
      link :self do uri :commit, id: represented.oid end
      link :tree do uri :tree, id: represented.tree_id end
      link :contents do uri :contents, ref: represented.tree_id end
    end

    class CommitRepresentation < BasicCommitRepresentation
      collection :diff, getter: lambda { |o, *| diff(reverse: true).to_a }, resolve: true
    end

    register_representation Rugged::Commit, CommitRepresentation
    register_representation Rugged::Commit, BasicCommitRepresentation, name: :basic

    register_representation Rugged::Blob do
      property :oid, as: :id
      property :content
      link :self do uri :blob, id: represented.oid end
    end

    register_representation Rugged::Tree do
      property :oid, as: :id
      collection :entries, decorator: TreeEntryRepresentation
      link :self do uri :tree, id: represented.oid end
    end

    register_representation Rugged::Diff::Patch do
      property :delta, resolve: true
      property :size
      property :additions
      property :deletions
      property :deletions
      collection :hunks, resolve: true
    end

    register_representation Rugged::Diff::Delta do
      property :old_file
      property :new_file
      property :similarity
      property :status
      property :binary
    end

    register_representation Rugged::Diff::Hunk do
      property :size
      property :header
      property :range
      collection :lines, resolve: true
    end

    register_representation Rugged::Diff::Line do
      property :line_origin
      property :content
      property :old_lineno
      property :new_lineno
    end

    protected

      def self.repository
        name = File.basename File.absolute_path config[:repo_path]
        Repository.new(name, config[:description], config[:default_branch] || 'master')
      end

      def git 
        Rugged::Repository.new("#{config[:repo_path]}/.git")
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
