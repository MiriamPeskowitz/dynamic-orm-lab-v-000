require_relative "../config/environment.rb"
require 'active_support/inflector' #supports pluralize
require 'pry'
class InteractiveRecord

    def self.table_name
        self.to_s.downcase.pluralize
    end

    def self.column_names
      DB[:conn].results_as_hash

      sql = "PRAGMA table_info('#{table_name}')"
      table_info = DB[:conn].execute(sql)
      column_names = []

      table_info.each do |column|
        column_names << column["name"]
      end
      column_names.compact #removes nil values
    end


    def initialize(options={})
      options.each do |property, value|
        self.send("#{property}=", value)
      end
    end #send -- metaproggraming. "We iterate over the options hash and use our fancy metaprogramming #send method to interpolate the name of each hash key as a method that we set equal to that key's value. As long as each property has a corresponding attr_accessor, this #initialize method will work."



#table names for insert?

    def col_names_for_insert
      self.class.column_names.delete_if {|col| col == "id"}.join(", ")
    end

    def table_name_for_insert
      self.class.table_name
    end


    def values_for_insert
      values = []

      self.class.column_names.each do |col_name|
        values << "'#{send(col_name)}'" unless send(col_name).nil?
      end
      values.join(", ")
    end

#to use a class method inside an instance method: self.class.methodName


    def save
      # save and grab id
      sql = "INSERT INTO #{self.table_name_for_insert} (#{col_names_for_insert}) VALUES (#{values_for_insert})"

      DB[:conn].execute(sql)

      @id = DB[:conn].execute("SELECT last_insert_rowid() FROM #{table_name_for_insert}")[0][0] #table name or table name for insert?
    end

    def self.find_by_name(name)
      sql = "SELECT * FROM #{self.table_name} WHERE name = '#{name}'" #wait where does this #{name} come from?
      DB[:conn].execute(sql)
    end

# use #values
    def self.find_by(attr_hash)
      value = attr_hash.values.first
      formatted_value = value.class == Fixnum ? value : "'#{value}'"
      sql = "SELECT * FROM #{self.table_name} WHERE #{attr_hash.keys.first} = #{formatted_value}"
      DB[:conn].execute(sql)
    end
  end 
