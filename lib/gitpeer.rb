require 'uri_template'
require 'rugged'

require 'gitpeer/version'
require 'gitpeer/controller'

module GitPeer

  module GitHelpers
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

  class Git < Controller
    include Controller::JSONRepresentation
    include GitHelpers

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

      json(path: path, ref: ref_name, commit: commit, tree: tree, blob: blob)
    end

    get :history do
      ref_name = param :ref
      after = param :after
      limit = param :limit, type: Integer, default: 30

      ref = or_404 { ref_by_name(ref_name) }
      commits = walk_from(after || ref.target)
      commits = commits.take(limit).to_a
      json(ref: ref_name, commits: commits, limit: limit, after: after)
    end

    [:branch, :tag, :commit, :tree, :blob, :object].each do |type|
      get type do
        obj = or_404 { repo.lookup(param :id) }
        not_found unless type == :object or obj.type == type
        json obj, with: representer_for(obj.type)
      end
    end

    module Representations
      include Controller::JSONRepresentation

      class Commit < Representation
        property :oid, as: :id
        property :message
        property :author
        property :committer
        property :tree_id
        link :self do uri :commit, id: represented.oid end
        link :tree do uri :tree, id: represented.tree_id end
      end

      class Blob < Representation
        property :oid, as: :id
        property :content
        link :self do uri :blob, id: represented.oid end
      end

      class TreeEntry < Representation
        hash_property :oid, as: :id
        hash_property :type
        hash_property :name
        link :self do
          uri represented[:type], id: represented[:oid]
        end
      end

      class Tree < Representation
        property :oid, as: :id
        collection :entries, extend: TreeEntry
        link :self do uri :tree, id: represented.oid end
      end
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

      def representer_for(type)
        case type
        when :commit
          Representations::Commit
        when :tree
          Representations::Tree
        when :blob
          Representations::Blob
        else
          raise "don't know how to represent #{type}"
        end
      end

  end

  class Comments < Controller
    uri :comments,  '/{oid}{?limit,after}'
    uri :comment,   '/{oid}/{cid}'

    get :comments
    post :comments
    get :comment
    put :comment
    delete :comment
  end

  class Wiki < Controller
    uri :wiki_history,  '/history{?limit,after}'
    uri :page_history,  '/history/{pid}{?limit,after}'
    uri :page,          '/page/{pid}'

    get :wiki_history
    get :page_history
    get :page
    put :page
    delete :page
  end

  class Issues < Controller
    uri :issues,    '/{?limit,after}'
    uri :issue,     '/{id}'

    get :issues
    post :issues
    get :issue
    put :issue
    delete :issue
  end
end
