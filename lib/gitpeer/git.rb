require 'rugged'
require 'gitpeer/controller'

module GitPeer
  class Git < Controller
    include Controller::JSONRepresentation

    uri :branch,    '/branch/{id}'
    uri :tag,       '/tag/{id}'
    uri :commit,    '/commit/{id}'
    uri :tree,      '/tree/{id}'
    uri :blob,      '/blob/{id}'
    uri :object,    '/{id}'
    uri :contents,  '/contents/{ref}{/path*}'
    uri :history,   '/history/{ref}{?limit,after}'

    get :contents do
      path = param :path
      ref_name = param :ref

      ref = or_404 { ref_by_name(ref_name) }
      commit = or_404 { repo.lookup(ref.resolve.target) }

      obj = if path
        entry = or_404 { commit.tree.path(path) }
        repo.lookup(entry[:oid])
      else
        commit.tree
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
      commits = walk_from(after || ref.target)
      commits = commits.take(limit).to_a
      json History.new(ref_name, limit, after, commits)
    end

    [:branch, :tag, :commit, :tree, :blob, :object].each do |type|
      get type do
        obj = or_404 { repo.lookup(param :id) }
        not_found unless type == :object or obj.type == type
        json obj
      end
    end

    Contents = Struct.new(:path, :ref, :commit, :blob, :tree)
    History = Struct.new(:ref, :limit, :after, :commits)

    class TreeEntryRepresentation < Representation
      value :oid, as: :id
      value :type
      value :name
      link :self do uri represented[:type], id: represented[:oid] end
    end

    register_representation Contents do
      property :path
      property :ref
      property :commit, resolve: true
      property :blob, resolve: true
      property :tree, resolve: true
      link :self do
        uri :contents, ref: represented.ref, path: represented.path
      end
    end

    register_representation History do
      property :ref
      property :limit
      property :after
      collection :commits, resolve: true
      link :self do
        uri :history, ref: represented.ref, limit: represented.limit, after: represented.after
      end
    end

    register_representation Rugged::Commit do
      property :oid, as: :id
      property :message
      property :author
      property :committer
      property :tree_id
      link :self do uri :commit, id: represented.oid end
      link :tree do uri :tree, id: represented.tree_id end
    end

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

    protected

      def branch_by_name(name)
        repo.ref("refs/heads/#{name}")
      end

      def tag_by_name(name)
        repo.ref("refs/tags/#{name}")
      end

      def ref_by_name(name)
        branch_by_name(name) || tag_by_name(name)
      end

      def walk_from(from_id)
        walker = Rugged::Walker.new(repo)
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
