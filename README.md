# DB2Query

[![Gem Version](https://badge.fury.io/rb/db2_query.svg)](https://badge.fury.io/rb/db2_query)

A Rails 5 & Rails 6 plugin for handling Db2 SQL database `SIUD` statement (`SELECT`, `INPUT`, `UPDATE`, `DELETE`) by using ODBC connection.

Note: Tested at Rails 5.2.6 and Rails 6.1.4

## Installation
Add this line to your application's Gemfile:

```ruby
gem 'db2_query'
```

And then execute:
```bash
$ bundle
```

Or install it yourself as:
```bash
$ gem install db2_query
```

## Initialization
Execute init task at the app root
```bash
$ rake db2query:init
```
Db2Query will generate two required files:
- `config/db2query.yml`
- `config/initializers/db2query.rb`

Edit those files according to the requirement.

### Database Configuration
At version 0.3.0, `db2query.yml` only use DSN connection config:
```yml
  development:
     dsn: ARUNIT
     pool: 5
     timeout: 5
  test:
     dsn: ARUNIT
     pool: 5
     timeout: 5
  production:
     dsn: ARUNIT
     pool: 5
     timeout: 5
```

Ensure that `unixodbc` have been installed and test your connection first by using `isql` commands.

Example:

Secondary database connection test
```bash
$ isql -v ARUNIT
+---------------------------------------+
| Connected!                            |
|                                       |
| sql-statement                         |
| help [tablename]                      |
| quit                                  |
|                                       |
+---------------------------------------+
SQL> 
```

## Usage
Note: Version 0.1.0 use `Db2Query` namespace. Version 0.2 use `DB2Query`. At version 0.3.0 we use `Db2Query`  , revert back to the previous namespace.

### Basic Usage
Create query class that inherit from `DB2Query::Base` in `app/queries` folder. 

Note: `$`symbol is used as column name prefix.

### 1. `query` method
The `query` method must have 2 inputs:
1. Method name
2. Body (can be an SQL statement or lamda).

The lambda is used to facilitate us in using `built-in methods` as shown at two query methods below:
Example 1.
```ruby
class User < Db2Query::Base
  query :find_by, <<-SQL
    SELECT * FROM LIBTEST.USERS WHERE $id = ?
  SQL
end
```
```bash
irb(main):004:0> User.find_by 10000
  SQL (3.2ms)  SELECT * FROM LIBTEST.USERS WHERE id = ?  [["id", 10000]]
=> #<Db2Query::Result [#<Record id: 10000, first_name: "Wilma", last_name: "Lindgren", email: "cleveland_kilback@breitenberg.com">]>
```
Example 2.
```ruby
class User < Db2query::Base
  query :id_greater_than, -> id {
    exec_query({}, "SELECT * FROM LIBTEST.USERS WHERE $id > ?", [id])
  }
end
```
```bash
irb(main):003:0> User.id_greater_than 10000
  SQL (3.2ms)  SELECT * FROM LIBTEST.USERS WHERE id > ?  [["id", 1000]]
=> #<Db2Query::Result [#<Record id: 10000, first_name: "Wilma", last_name: "Lindgren", email: "cleveland_kilback@breitenberg.com">...">]>
```
Example 3.
```ruby
class User < Db2query::Base
  query :insert_record, -> args {
    exec_query({},
      "INSERT INTO users ($id, $first_name, $last_name, $email) VALUES (?, ?, ?, ?)", args
  )
}
end
```
```bash
```

### 2. Plain/normal method
At a plain/normal sql method we add `_sql` suffix. For example `find_by_sql`
```ruby
class User < Db2Query::Base 
  def find_by_sql
    "SELECT * FROM LIBTEST.USERS WHERE $id = ?"
  end
end
```
Then we can call it by using `find_by` class method.
```bash
irb(main):001:0> User.find_by 10000
SQL Load (3.28ms)  SELECT * FROM LIBTEST.USERS WHERE id = ? [[nil, 10000]]
=> #<DB2Query::Result @records=[#<Record id: 10000, first_name: "Strange", last_name: "Stephen", email: "strange@marvel.universe.com">]>
```
Or with hash arguments input
```ruby
class User < Db2Query::Base 
	def  by_name_and_email_sql
		"SELECT * FROM LIBTEST.USERS WHERE $first_name = ? AND $email = ?"
	end
end
```
```bash
irb(main):001:0> User.by_name_and_email first_name: "Strange", email: "strange@marvel.universe.com"
SQL Load (3.28ms)  SELECT * FROM LIBTEST.USERS WHERE first_name = ? AND last_name = ? [["first_name", Strange], ["email", strange@marvel.universe.com]]
=> #<DB2Query::Result @records=[#<Record id: 10000, first_name: "Strange", last_name: "Stephen", email: "strange@marvel.universe.com">]>
```
###  SQL extention (`@extention`)
For a reusable sql, we can extend it by using a combination of `extention` and `sql_with_extention` methods,  with an `@extention` pointer at SQL statement.
```ruby
class User < Db2Query::Base
    # reusable SQL
	_SQL = -> extention {
		sql_with_extention("SELECT * FROM LIBTEST.USERS WHERE @extention", extention)
	}
    # implementation
    query :by_email, _SQL.("$email = ?")
end
```
```bash
irb(main):004:0> User.by_email "strange@marvel.universe.com"
  SQL (3.2ms)  SELECT * FROM LIBTEST.USERS WHERE email = ?  [["email", "strange@marvel.universe.com"]]
=> #<DB2Query::Result @records=[#<Record id: 10000, first_name: "Strange", last_name: "Stephen", email: "strange@marvel.universe.com">]> 
```
### List input (`@list`)
For an array consist list of inputs, we can use `fetch_list` method and `@list` pointer at the SQL statement.

```ruby
class User < Db2Query
	query :by_ids, -> ids {
		fetch_list("SELECT * FROM LIBTEST.USERS WHERE ID IN (@list)", ids)
	}
end
```
```bash
irb(main):007:0> User.by_ids [10000,10001,10002]
  SQL (2.8ms)  SELECT * FROM LIBTEST.USERS WHERE ID IN ('10000', '10001', '10002')
=> #<Db2Query::Result [#<Record id: 10000, name: "Carol", last_name: "Danvers", email: "captain.marvel@marvel.universe.com">, #<Record id: 10001, first_name: "Natasha", last_name: "Romanova", email: "black.widow@marvel.universe">, #<Record id: 10002, first_name: "Wanda", last_name: "Maximoff", email: "scarlet.witch@marvel.universe.com">]>

```

### Formatter
In order to get different result column format, a query result can be reformatted by adding a formatter class that inherits `DB2Query::AbstractFormatter` then register at `config\initializers\db2query.rb`
```ruby
require "db2_query/formatter"

# create a formatter class
class FirstNameFormatter < Db2Query::AbstractFormatter
  def format(value)
    "Dr." + value
  end
end

# register the formatter class
Db2Query::Formatter.registration do |format|
  format.register(:first_name_formatter, FirstNameFormatter)
end
```
Use it at query class
```ruby
class Doctor < User
  attributes :first_name, :first_name_formatter
end
```
Check it at rails console
```bash
Doctor.find_by id: 10000
SQL Load (3.28ms)  SELECT * FROM LIBTEST.USERS WHERE id = ? [["id", 10000]]
=> #<DB2Query::Result @records=[#<Record id: 10000, first_name: "Dr.Strange", last_name: "Stephen", email: "strange@marvel.universe.com">]>
```

For complete examples please see the basic examples [here](https://github.com/yohaneslumentut/db2_query/blob/master/test/dummy/app/queries/test_query.rb).

### Available Result Object methods
`Db2Query::Result` inherit all `ActiveRecord::Result` methods with additional custom methods:
  1. `records` to convert query result into array of Record objects.
  2. `to_h` to convert query result into hash with symbolized keys.

### Built-in methods
These built-in methods are delegated to `Db2Query::Connection` methods
  1. `query_rows(sql)`
  2. `query_value(sql)`
  3. `query_values(sql)`
  4. `execute(sql)`
  5. `exec_query(formatters, sql, args = [])`
They behave just likely `ActiveRecords` connection's public methods.

### ActiveRecord Combination

Create an abstract class that inherit from `ActiveRecord::Base`
```ruby
class Db2Record < ActiveRecord::Base
  self.abstract_class = true

  def self.query(formatter, sql, args = [])
    Db2Query::Base.connection.exec_query(formatter, sql, args).to_a.map(&:deep_symbolize_keys)
  end
end
```

Utilize the goodness of rails model `scope`
```ruby
class User < Db2Record
  scope :by_name, -> *args {
    query(
      {}, "SELECT * FROM LIBTEST.USERS WHERE $first_name = ? AND $last_name = ?", args
    )
  }
end
```
```bash
User.by_name first_name: "Strange", last_name: "Stephen"
SQL Load (3.28ms)  SELECT * FROM LIBTEST.USERS WHERE first_name = ? AND last_name = ? [["first_name", Strange], ["last_name", Stephen]]
=> [{:id=> 10000, :first_name=> "Strange", :last_name=> "Stephen", :email=> "strange@marvel.universe.com"}]
```

Another example:
```ruby
class User < Db2Record
  scope :age_gt, -> age {
    query("SELECT * FROM LIBTEST.USERS WHERE age > #{age}")
  }
end
```

```bash
User.age_gt 500
SQL Load (3.28ms)  SELECT * FROM LIBTEST.USERS WHERE age > 500
=> [{:id=> 99999, :first_name=> "Ancient", :last_name=> "One", :email=> "ancientone@marvel.universe.com"}]
```

## License
The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).