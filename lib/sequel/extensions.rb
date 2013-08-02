module Sequel

  class Dataset

    def insert_from(data)
      data = data.to_h unless data.is_a? Hash
      insert data.select { |k, v| columns.include? k }
    end

    def as(cls)
      to_a.map do |row|
        values = cls.members.map { |k| row[k] }
        cls.new(*values)
      end
    end

  end
end

