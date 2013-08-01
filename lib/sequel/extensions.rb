module Sequel

  class Dataset
    def as(cls)
      to_a.map do |row|
        values = cls.members.map { |k| row[k] }
        cls.new(*values)
      end
    end
  end
end

