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
      prop :c do
        @obj.a + @obj.b
      end
    end

    repr = MyRepr.new(OpenStruct.new(a: 1, b: 2))
    repr.to_hash.should == {c: 3}
  end

  it 'allows representations to depend on context' do
    class ContextualRepr < GitPeer::Representation
      prop :c do
        @context[:b] + @obj.a
      end
    end

    repr = ContextualRepr.new(OpenStruct.new(a: 1), b: 2)
    repr.to_hash.should == {c: 3}
  end

  it 'allows define props with their own representations' do
    class BRepr < GitPeer::Representation
      prop :c
    end
    class ARepr < GitPeer::Representation
      prop :a
      prop :b, repr: BRepr
    end

    repr = ARepr.new(OpenStruct.new(a: 1, b: OpenStruct.new(c: 2)))
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
end
