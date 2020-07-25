# Db2Query

A Rails query plugin to fetch data from Db2 database by using ODBC connection.

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
- `config/db2query_database.yml`
- `config/initializers/db2query`

Edit these files according to the requirement.

### Database Configuration
At `db2query_database.yml` we can use two type of connection:
1. DSN connection config
2. Connection String config
```yml
development:
  primary:                         # Connection String Example
    conn_string:
      driver: DB2
      database: SAMPLE
      dbalias: SAMPLE
      hostname: LOCALHOST
      currentschema: LIBTEST
      port: "0"
      protocol: IPC
      uid: <%= ENV["DB2EC_UID"] %>
      pwd: <%= ENV["DB2EC_PWD"] %>
  secondary:                       # DSN Example
    dsn: SAMPLE
    uid: <%= ENV["DB2EC_UID"] %>
    pwd: <%= ENV["DB2EC_PWD"] %>
```

## Usage
### Basic Usage
Create query class that inherit from `Db2Query::Base` in `app/queries` folder
```ruby
class Users < Db2Query::Base
  query :find_by, <<-SQL
    SELECT * FROM LIBTEST.USERS WHERE user_id = ?
  SQL
end
```
Or use a normal sql method (don't forget the `_sql` suffix)
```ruby
class Users < Db2Query::Base 
  def find_by_sql
    "SELECT * FROM LIBTEST.USERS WHERE user_id = ?"
  end
end
```
Check it at rails console
```bash
Users.find_by 10000
Users Load (330.28ms)  SELECT * FROM LIBTEST.USERS WHERE user_id = ? [[10000]]
=> #<Db2Query::Result [#<Users::FindBy user_id: 10000, first_name: "Alex", last_name: "Jacobi", email: "lula_durgan@dooley.com">]>
```
### Formatter
In order to get different result column format, a query result can be reformatted by add a formatter class that inherit `Db2Query::AbstractFormatter` then register at `config\initializers\db2query.rb`
```ruby
require "db2_query/formatter"

# create a formatter class
class FirstNameFormatter < Db2Query::AbstractFormatter
  def format(value)
    "Mr/Mrs. " + value
  end
end

# register the formatter class
Db2Query::Formatter.registration do |format|
  format.register(:first_name_formatter, FirstNameFormatter)
end
```
Use it at query class
```ruby
class Users < Db2Query::Base
  attributes :first_name, :first_name_formatter

  query :find_by, <<-SQL
    SELECT * FROM LIBTEST.USERS WHERE user_id = ?
  SQL
end
```
Check it at rails console
```bash
Users.find_by 10000
Users Load (330.28ms)  SELECT * FROM LIBTEST.USERS WHERE user_id = ? [[10000]]
=> #<Db2Query::Result [#<Users::FindBy user_id: 10000, first_name: "Mr/Mrs. Alex", last_name: "Jacobi", email: "lula_durgan@dooley.com">]>
```
### Available methods
Db2Query::Result has public methods as follows:
- to_a
- to_hash
- pluck
- first
- last
- size
- each


## License
The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
