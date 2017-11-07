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

    def self.find_by(attr_hash) #have some names, fnd it in the db
      sql = "SELECT * FROM '#{self.table_name}' WHERE id = attr_hash[:id], name = attr_hash[:name], grade = attr_hash[:grade]"
      binding.pry

      # Possibile to take the hash apart ? then look for these
      # attr_hash[:id]
      # attr_hash[:name]
      # attr_hash[:grade]

      DB[:conn].execute(sql)
    end

    # attr_hash = {
    #   id => id
    #   name => name
    #   grade => grade
    # }
    #
    # self.id = attr_hash[:id]
    # self.name = attr_hash[:name]
    # self.grade = attr_hash[:grade]

#maybe try a reify_from_row? -- no, that's for a row/values only , not a hash
  #
  # self.reify_from_row(row)
  #   self.new.tap do |o|
  #     o.id = row[0]
  #     o.name = row[1] etc

      #Spec file
    # it 'executes the SQL to find a row by the attribute passed into the method' do
    #   Student.new({name: "Susan", grade: 10}).save
    #   expect(Student.find_by({name: "Susan"})).to eq([{"id"=>1, "name"=>"Susan", "grade"=>10, 0=>1, 1=>"Susan", 2=>10}])
    # end
    #
    # it 'accounts for when an attribute value is an integer' do
    #   Student.new({name: "Susan", grade: 10}).save
    #   expect(Student.find_by({grade: 10})).to eq([{"id"=>1, "name"=>"Susan", "grade"=>10, 0=>1, 1=>"Susan", 2=>10}])
    # end
end
