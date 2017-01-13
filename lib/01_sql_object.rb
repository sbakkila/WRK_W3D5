require_relative 'db_connection'
require 'active_support/inflector'
require 'byebug'
# NB: the attr_accessor we wrote in phase 0 is NOT used in the rest
# of this project. It was only a warm up.

class SQLObject
  def self.columns

    @columns ||= DBConnection.execute2(<<-SQL)
      SELECT
        *
      FROM
        #{table_name}
    SQL
    .first.map{|ele| ele.to_sym}
  end


  def self.finalize!

    columns.each do |col|
      define_method(col.to_s.concat('=')) do |arg|
        self.attributes[col] = arg
      end
    end

    columns.each do |col|
      define_method(col) do
        self.attributes[col]
      end
    end


  end

  def self.table_name=(table_name)
    @table_name = table_name
  end

  def self.table_name
    @table_name ||= self.name.tableize
  end

  def self.all

    results = DBConnection.execute(<<-SQL)
    SELECT
      #{table_name}.*
    FROM
      #{table_name}
    SQL
    # debugger
    self.parse_all(results)
  end

  def self.parse_all(results)
    results.map do |result|
      self.new(result)
    end
  end

  def self.find(id)
    results = DBConnection.execute(<<-SQL, id)
    SELECT
      #{table_name}.*
    FROM
      #{table_name}
    WHERE
      #{table_name}.id = ?
    SQL
    parse_all(results).first
  end

  def initialize(params = {})
    params.each do |attr_name, val|
      # debugger
      attr_name = attr_name.to_sym
      raise "unknown attribute '#{attr_name}'" unless self.class.columns.include?(attr_name)
      self.send("#{attr_name}=", val)
    end
  end

  def attributes
    @attributes ||= Hash.new
  end

  def attribute_values
    self.class.columns.map{ |attr| self.send(attr)}
  end

  def insert
    columns = self.class.columns.join(", ")
    n = self.class.columns.count
    question_marks = ['?'] * n
    question_marks = question_marks.join(', ')

    values = DBConnection.execute(<<-SQL, *self.attribute_values)
      INSERT INTO
        #{self.class.table_name} (#{columns})
      VALUES
        (#{question_marks})
    SQL

    self.id = DBConnection.last_insert_row_id
  end

  def update

    set = self.class.columns.map { |column| "#{column.to_s} = ?"}.join(", ")

    DBConnection.execute(<<-SQL, attribute_values, id)
    UPDATE
      #{self.class.table_name}
    SET
      #{set}
    WHERE
      #{self.class.table_name}.id = ?
    SQL

  end

  def save
    id.nil? ? self.insert : self.update

  end

end
