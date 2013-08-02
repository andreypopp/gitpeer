module Sequel

  class Dataset

    def insertFrom(data)
      insert data.to_h.select { |k, v| columns.include? k }
    end

    def as(cls)
      to_a.map do |row|
        values = cls.members.map { |k| row[k] }
        cls.new(*values)
      end
    end

  end
end

