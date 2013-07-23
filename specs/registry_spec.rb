require 'gitpeer'
require 'gitpeer/registry'

describe GitPeer::Registry do

  class IA; end
  class IB < IA; end

  it 'allows to query components for superinterfaces' do
    components = GitPeer::Registry.new()
    components.register(1, IA)
    components.query(IA).should eq 1
    components.query(IB).should eq 1
  end

  it 'allows to override components for superinterfaces' do
    components = GitPeer::Registry.new()
    components.register(1, IA)
    components.query(IA).should eq 1
    components.query(IB).should eq 1
    components.register(2, IB)
    components.query(IA).should eq 1
    components.query(IB).should eq 2
  end

  it 'allows to register different components by different names' do
    components = GitPeer::Registry.new()
    components.register(1, IA)
    components.register(2, IA, name: 'yeah')
    components.query(IA).should eq 1
    components.query(IB).should eq 1
    components.query(IA, name: 'yeah').should eq 2
    components.query(IB, name: 'yeah').should eq 2
  end

  it 'disallows overriding registrations' do
    components = GitPeer::Registry.new()
    components.register(1, IA)
    expect { components.register(1, IA) }.to raise_error(GitPeer::Registry::ConflictError)
    components.query(IA).should eq 1
  end

  it 'allows overriding registrations if corresponding argument is provided' do
    components = GitPeer::Registry.new()
    components.register(1, IA)
    components.register(2, IA, override: true)
    components.query(IA).should eq 2
  end

  it 'returns nil if component is not found on query' do
    components = GitPeer::Registry.new()
    components.query(IA).should eq nil
  end

  it 'raises a LookupError if component is not found on get' do
    components = GitPeer::Registry.new()
    expect { components.get(IA) }.to raise_error(GitPeer::Registry::LookupError)
  end
end
