require 'ostruct'
require 'gitpeer'
require 'gitpeer/representation'

describe GitPeer::Representation do

  User = Struct.new(:name, :birthday)

  class UserRepr < GitPeer::Representation
    prop :name
    prop :birthday
    link :self, href: '/x'
  end

  it 'renders props and links' do
    repr = UserRepr.new(User.new("Andrey", "1987"))
    repr.to_hash.should == {
      name: "Andrey",
      birthday: "1987",
      _links: {self: {href: '/x'}}
    }
  end

  it 'represents values from hashes' do
    repr_cls = Class.new(GitPeer::Representation) do
      value :id
    end
    repr = repr_cls.new({id: 1})
    repr.to_hash.should == {id: 1}
  end

  it 'allows getting props from different name' do
    class Repr < GitPeer::Representation
      prop :a, from: :b
    end

    repr = Repr.new(OpenStruct.new(b: 2))
    repr.to_hash.should == {a: 2}
  end

  PowerUser = Struct.new(:name, :birthday, :power)
  class PowerUserRepr < UserRepr
    prop :power
    link :power, href: '/y', templated: true
  end

  it 'allows subclassing representations' do
    repr = PowerUserRepr.new(PowerUser.new("Andrey", "1987", 100))
    repr.to_hash.should == {
      name: "Andrey",
      birthday: "1987",
      power: 100,
      _links: {
        self: {href: '/x'},
        power: {href: '/y', templated: true}
      }
    }
  end

  it 'allows computed props' do
    class MyRepr < GitPeer::Representation
      prop :c, from: proc { @obj.a + @obj.b }
    end

    repr = MyRepr.new(OpenStruct.new(a: 1, b: 2))
    repr.to_hash.should == {c: 3}
  end

  it 'allows representations to depend on context' do
    class ContextualRepr < GitPeer::Representation
      prop :c, from: proc { @context[:b] + @obj.a }
    end

    repr = ContextualRepr.new(OpenStruct.new(a: 1), b: 2)
    repr.to_hash.should == {c: 3}
  end

  it 'allows define props with their own representations' do
    brepr = Class.new(GitPeer::Representation) do
      prop :c
    end
    arepr = Class.new(GitPeer::Representation) do
      prop :a
      prop :b, repr: brepr
    end

    repr = arepr.new(OpenStruct.new(a: 1, b: OpenStruct.new(c: 2)))
    repr.to_hash.should == {a: 1, b: {c: 2}}
  end
  
  it 'allows define props with inline representations' do
    arepr = Class.new(GitPeer::Representation) do
      prop :a
      prop :b do
        prop :c
      end
    end

    repr = arepr.new(OpenStruct.new(a: 1, b: OpenStruct.new(c: 2)))
    repr.to_hash.should == {a: 1, b: {c: 2}}
  end

  it 'allows override props' do
    class XRepr < GitPeer::Representation
      prop :a
    end
    class YRepr < XRepr
      prop :a, from: :b
    end

    repr1 = XRepr.new(OpenStruct.new(a: 1, b: 2))
    repr1.to_hash.should == {a: 1}
    repr2 = YRepr.new(OpenStruct.new(a: 1, b: 2))
    repr2.to_hash.should == {a: 2}
  end

  describe 'representing links with URI templates' do

    it 'allows representing templated links with URI templates' do
      repr_class = Class.new(GitPeer::Representation) do
        link :self, template: '/{x}', templated: true
      end
      repr = repr_class.new(OpenStruct.new(x: 1))
      repr.to_hash.should == {_links: {self: {href: '/{x}', templated: true}}}
    end

    it 'expands URI template if link is not meant to be templated' do
      repr_class = Class.new(GitPeer::Representation) do
        prop :x
        link :self, template: '/{x}'
      end
      repr = repr_class.new(OpenStruct.new(x: 1))
      repr.to_hash.should == {x: 1, _links: {self: {href: '/1'}}}
    end
  end

  describe 'representing collections' do

    it 'represents collections as arrays' do
      a = Class.new(GitPeer::Representation) do
        collection :a
        collection :b
      end
      repr = a.new(OpenStruct.new(a: [1, 2], b: [1, 2].to_enum))
      repr.to_hash.should == {a: [1, 2], b: [1, 2]}
    end

    it 'allows to represent elements in collection with custom representer' do
      ea = Class.new(GitPeer::Representation) do
        prop :a, from: :b
      end
      a = Class.new(GitPeer::Representation) do
        collection :a, repr: ea
      end
      repr = a.new(OpenStruct.new(a: [OpenStruct.new(b: 2)]))
      repr.to_hash.should == {a: [{a: 2}]}
    end

    it 'allows to represent elements in collection with inline representer' do
      a = Class.new(GitPeer::Representation) do
        collection :a do
          prop :a, from: :b
        end
      end
      repr = a.new(OpenStruct.new(a: [OpenStruct.new(b: 2)]))
      repr.to_hash.should == {a: [{a: 2}]}
    end
  end

  describe 'representation error' do

    it 'fails if represented obj cannot respond to needed methods' do
      class FailRepr1 < GitPeer::Representation
        prop :x
      end
      expect { 
        FailRepr1.new(OpenStruct.new(z: 1)).to_hash
      }.to raise_error(GitPeer::Representation::RepresentationError)
    end

    it 'fails if represented obj cannot respond to needed methods' do
      class FailRepr2 < GitPeer::Representation
        prop :x, from: :y
      end
      expect { 
        FailRepr2.new(OpenStruct.new(x: 1)).to_hash
      }.to raise_error(GitPeer::Representation::RepresentationError)
    end

  end

  describe 'automatic representation generation for Structs' do

    it 'automatically generates representations for Structs' do
      user = Struct.new(:name, :age)
      repr = GitPeer::Representation.for_struct(user)
      repr.new(user.new("Andrey", 27)).to_hash.should == {name: "Andrey", age: 27}
    end

    it 'allows to override generated representation' do
      user = Struct.new(:name, :age)
      repr = GitPeer::Representation.for_struct(user) do
        prop :age, from: proc { obj.age + 3 }
      end
      repr.new(user.new("Andrey", 27)).to_hash.should == {name: "Andrey", age: 30}
    end

  end

end
