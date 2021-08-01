# Db2Query

[![Gem Version](https://badge.fury.io/rb/db2_query.svg)](https://badge.fury.io/rb/db2_query)

A Rails 5 & Rails 6 plugin for handling Db2 SQL database `SIUD` statement (`SELECT`, `INSERT`, `UPDATE`, `DELETE`) by using ODBC connection.

Note: Tested at Rails 5.2.6 and Rails 6.1.4

## 1. Installation
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
## 2. Initialization
Execute **db2query:init** task at the app root to create database configurations and initializer file.
```bash
$ rake db2query:init
      create  config/db2query.yml
      create  config/initializers/db2query.rb
```

Complete the configurations by editing the files according to your application requirement.

### Database Configuration
File **config/db2query.yml** consist of DSN/database name and connection pool config:
```yml
  development:
     dsn: ARUNIT
     idle: 5
     pool: 5
     timeout: 5
  test:
     dsn: ARUNIT
     idle: 5
     pool: 5
     timeout: 5
  production:
     dsn: ARUNIT
     idle: 5
     pool: 5
     timeout: 5
```

Key **idle** is a **client** idle maximum limit value (in minutes) to avoid the client being disconnected by the host server. Setting this value to zero will lead to an "ODBC driver Communication Link Failure. Comm rc 10054 . [CWBCO1047](https://www.ibm.com/support/pages/cwbco1047-any-function-uses-database-host-server)" error after your application idle in a certain period of time.

[**Ensure**](https://github.com/yohaneslumentut/db2_query/wiki/DB2-ODBC-Connection#verify-odbc-connection) that **unixodbc** has been installed and test your connection first by using **isql** commands.

### Initializer File
This file is used by **Db2Query::Base** to load **field types** configurations and establish a **connection** instance.
```ruby
# app_root/config/initializers/db2query.rb

require "db2_query"

Db2Query::Base.initiation do |base|
  base.set_field_types  # or base.set_field_types(CUSTOM_FIELD_TYPES) if you have CUSTOM TYPES
  base.establish_connection
end
```

### Custom Field Type
**FieldTypes** are classes that used by **Db2Query** to format the data before sending it to the database by using `serialize` method and converting the **query result** before consumed by your **Rails application** by using `deserialize` method. Both `serialize` and `deserialize` operations are only applied when you provide **QueryDefinitions** on your query. By default, there are ten field types that can be used in your [query definitions](#32-querydefinitions) :

```ruby
  DEFAULT_FIELD_TYPES = {
    binary: Db2Query::Type::Binary,
    boolean:  Db2Query::Type::Boolean,
    string: Db2Query::Type::String,
    varchar: Db2Query::Type::String,
    longvarchar: Db2Query::Type::String,
    decimal: Db2Query::Type::Decimal,
    integer: Db2Query::Type::Integer,
    date: Db2Query::Type::Date,
    time: Db2Query::Type::Time,
    timestamp: Db2Query::Type::Timestamp
  }
```
You can use your own Field type class by extending **Db2Query::Type::Value** class. For example:
```ruby
  class CustomTypeClass < Db2Query::Type::Value
    # Method to convert data from ruby type value into data that is understood by Db2
    def serialize(value)
      # Your logic 
    end
   
    # Method to convert Db2 database output data type that is recognized by your rails app
    def deserialize(value)
      # Your logic
    end
 end
```
Then map the classes into a variable and load it into the **Db2Query::Base** by using **set_field_types** method in the initializer file.
```ruby
# app_root/config/initializers/db2query.rb

require "db2_query"
 
CUSTOM_FIELD_TYPES = {
   binary: CustomBinaryTypeClass
   integer: CustomIntegerTypeClass
   string: CustomStringTypeClass
   ...
}

Db2Query::Base.initiation do |base|
  base.set_field_types(CUSTOM_FIELD_TYPES)
  base.establish_connection
end

```

## 3. Usage

Once you completely do [**Installation**](#1-installation) & [**Initialization**](#2-initialization), basically you has been ready to use **Db2Query::Base** with three additional conventions: **SQL Convention**, **Field Type Convention**, **Argument Key Convention**.

**SQL Convention**:
> **"** Dollar symbol **$** is used as the prefix of all column names **in the WHERE clause** of provided **Parameterized Query** SQL string. It is used as a pointer in the binding process of key and value of query arguments. We have to provide it manually in the SQL string of each **Parameterized Query**. Here, **Parameterized Query** is used to minimize SQL injection risks.**"**

**Field Type Convention**:
> **"** **field_name** written in **query_definition** block must be in downcased format.**"**

**Argument Key Convention**:
> **"** **Argument Key** passed into query have to follow its parameter written in the SQL. It is case-sensitive. If the parameter in your SQL is written in downcase format, then your argument key has to be in downcase format too.**"**


```ruby
# SQL Convention Examples
# Example of Parameterized Query SQL usage

Db2Query::Base.query("SELECT * FROM USERS WHERE $email = ?", "my_account@email.com")

# Example of Normal SQL usage

Db2Query::Base.query("SELECT * FROM USERS WHERE email = 'my_account@email.com'")

# Field Type Convention Example

module Definitions
  class UsersQueryDefinitions < Db2Query::Definitions
    def describe
      query_definition :all do |c|
        c.id          :integer
        c.first_name  :varchar
        c.last_name   :varchar
        c.email       :varchar
      end
    end
  end
end

# Argument Key Convention Example

MyQuery.find_user_by_id id: 10000

```


### 3.1 Basic Usage

#### Base Class Query Methods

##### #query(sql, args)
A raw query to perform a `connection.run(sql, args)` operation and returns an array of hashes representing each row record being executed.
```ruby
Db2Query::Base.query("SELECT * FROM USERS WHERE $id < ?", 10003)
=> [{:id=>10000, :first_name=>"Taisha", :last_name=>"Kutch", :email=>"willie.lesch@toy.org"}, {:id=>10001, :first_name=>"Setsuko", :last_name=>"Kutch", :email=>"thelma@purdy.co"}, {:id=>10002, :first_name=>"Trina", :last_name=>"Mayer", :email=>"dorsey_upton@flatley-gulgowski.name"}]
```

##### #query_rows(sql)
Execute the `SELECT Statement SQL` and returns collections of arrays consisting of row values.
```ruby
Db2Query::Base.query_rows("SELECT * FROM USERS WHERE id < 10003")
=> [[10000, "Taisha", "Kutch", "willie.lesch@toy.org"], [10001, "Setsuko", "Kutch", "thelma@purdy.co"], [10002, "Trina", "Mayer", "dorsey_upton@flatley-gulgowski.name"]]
```

##### #query_value(sql)
Execute the `SELECT Statement SQL` and returns the first value of the query results first row.
```ruby
Db2Query::Base.query_value("SELECT * FROM USERS WHERE id < 10003")
=> 10000
```

##### #query_values(sql)
Execute the `SELECT Statement SQL` and returns a collection of the first value of each query result rows.
```ruby
Db2Query::Base.query_values("SELECT * FROM USERS WHERE id < 10003")
=> [10000, 10001, 10002]
```

##### #execute(sql, args)
A method to execute `DUI Statement SQL` by using `connection.do(sql, args)`
```ruby
Db2Query::Base.execute("DELETE FROM users WHERE $id = ?", 10000)
=> -1
```

### 3.2 QueryDefinitions

QueryDefinitions is helpful when you need formatter methods that **serialize** the data before it being sent to the database and **deserialize** database output data before being consumed by **Rails application**. The real examples are **Binary** and **Boolean** field types.
At **Db2Query::Type::Binary**, the data `unpacked` by `serialize` method before sending to the database and do `deserialize` operation to `pack` the database returned data.
QueryDefinition can be used as **Query Schema** where the **field types** of a query are outlined. The field-type written in QueryDefinition has to follow the **Field Type Convention**.

A QueryDefinitions reside in `app_root/app/queries/definitions` directory. It is automatically created when you create your query by using run `rails g query query_name` [**generator**](#33-generator) command. The QueryDefinitions class can be defined as follow:
```ruby
# app_root/app/queries/definitions/your_query_definitions.rb
module Definitions
  class YourQueryDefinitions < Db2Query::Definitions
    def describe  # method that is used by Db2Query to describe your query definition
      query_definition :your_first_query_name do |c|
        c.field_name     :field_type, options 
        ...
      end

      query_definition :your_next_query_name do |c|
        c.field_name     :field_type, options 
        ...
      end
    end
  end
end
```
For Example:

```ruby
# app_root/app/queries/definitions/users_query_definitions.rb

module Definitions
  class UsersQueryDefinitions < Db2Query::Definitions
    def describe
      query_definition :all do |c|
        c.id          :integer
        c.first_name  :varchar
        c.last_name   :varchar
        c.email       :varchar
      end

      query_definition :insert do |c|
        c.id          :integer
        c.first_name  :varchar
        c.last_name   :varchar
        c.email       :varchar
      end
    end
  end
end

```


### 3.3 Generator

Create query class by using `rails g query NAME` commands. For example:

```bash
$ rails g query NameSpace::Name --defines=first_query --queries=next_query  --lambdas=last_query
    create app/queries/name_space/name_query.rb
    create  app/queries/definitions/movies_query_definitions.rb
    create test/queries/name_space/name_query_test.rb
```
This will create `app/queries/name_space/name_query.rb` file in `app/queries` directory.

```ruby
module NameSpace
  class Name < Db2Query::Base
    def first_query_sql

    end

    query :next_query, <<-SQL

    SQL

    query :last_query, -> {
      
    }
  end
end
```

```ruby
# app_root/app/queries/definitions/name_space/name_query.rb

module Definitions
  module NameSpace
    class NameQueryDefinition < Db2Query::Definitions
      def describe  # method that is used by Db2Query to describe your query definition
        query_definition :first_query do |c|

        end

        query_definition :next_query do |c|

        end

        query_definition :last_query do |c|

        end
      end
    end
  end
end
```

Please run `rails g query --help` to get more information on how to use the file generator.

### 3.4 Queries Methods

In a **Query** class that extends **Db2Query::Base** class, there are 3 ways of query implementation:

```ruby
class MyQuery < Db2Query::Base
  # 1. Plain Query (--defines)
  def query_name_sql
    "YOUR AMAZING SQL STATEMENT STRING"
  end

  # 2. String Query (--queries)
  query :query_name, <<-SQL
    YOUR AMAZING SQL STATEMENT
  SQL

  # 3. Lambda Query (--lambdas)
  query :query_name, -> args {
    # implement fetch, fetch_list, and exec_query
     fetch("YOUR AMAZING SQL", args)
  }
end
```

#### 3.4.1 Plain Query (--defines)
Query implementation that uses the plain method. The method name must have a `_sql` suffix and return SQL statement string.

Example:
```ruby
class MyQuery < Db2Query::Base
  def all_users_sql
    "SELECT * FROM USERS"
  end

  def find_user_by_id_sql
    "SELECT * FROM USERS WHERE $id = ?"
  end
end
```

#### 3.4.2 String Query (--queries)
Query implementation that uses the built-in `query` method. The input arguments consist of `query_name` symbol and SQL statement

Example:
```ruby
class MyQuery < Db2Query::Base
  query :all_users, <<-SQL
    SELECT * FROM USERS
  SQL

  query :find_user_by_id, <<-SQL
    SELECT * FROM USERS WHERE $id = ?
  end
end
```

#### 3.4.3 Lambda Query (--lambdas)
Query implementation that uses the built-in `query` method. The input arguments consist of the `query_name` symbol and a lambda function. We have to pass `args` as the arguments of a lambda function. Do not change the `args` with let's say `-> id, email { ... }`. Just leave it written as `args`. The `args` is used by `Db2Query::Base` to store `query_name` and the other `arg` inputs.

Example:
```ruby
class MyQuery < Db2Query::Base
  query :all_users, -> args {
    fetch("SELECT * FROM USERS", args)
  }

  query :find_user_by_id, -> args {
    fetch("SELECT * FROM USERS WHERE $id = ?", args)
  }
end
```

Then you can call all three example with the same methods:

```bash
irb(main):001:0> MyQuery.all_users
  SQL (2.7ms)  SELECT * FROM USERS
=> #<Db2Query::Result [#<Record id: 10000, first_name: Yohanes, ...]>

irb(main):001:0> MyQuery.find_user_by_id 10000
  SQL (3.0ms)  SELECT * FROM USERS WHERE id = ?  [["id", 10000]]
=> #<Db2Query::Result [#<Record id: 10004, first_name: Yohanes, ...]>
```
If you pass a key-value argument into query, the key has to follow **Argument Key Convention**

```bash
irb(main):001:0> MyQuery.find_user_by_id(id: 10000)
  SQL (3.0ms)  SELECT * FROM USERS WHERE id = ?  [["id", 10000]]
=> #<Db2Query::Result [#<Record id: 10004, first_name: Yohanes, ...]>

```

And use it at your application
```ruby
users = MyQuery.all
user_records = users.records
user_1 = user_records.first
user_1.id         # => 10000
user_1.first_name # => "Yohanes"
user_1.last_name  # => "Lumentut"
user_1.email      # => "yohanes@github.com"

user_1 == users.record   # => true

user = MyQuery.find_user_by_id id: 10000
user.id         # => 10000
user.first_name # => "Yohanes"
user.last_name  # => "Lumentut"
user.email      # => "yohanes@github.com"
```

### 3.5 SQL extention (`@extention`)
For a reusable `sql`, we can extend it by using a combination of `extention` and `sql_with_extention` methods,  with an `@extention` pointer at SQL statement.
```ruby
class MyQuery < Db2Query::Base
  # reusable SQL
  _SQL = -> extention {
    sql_with_extention("SELECT * FROM USERS WHERE @extention", extention)
  }
  
  # implementation
  query :user_by_email, _SQL.("$email = ?")
end
```
```bash
irb(main):001:0> MyQuery.user_by_email
  SQL (2.7ms)  SELECT * FROM USERS email = ?  [["email", "yohanes@github.com"]]
=> #<Db2Query::Result [#<Record id: 10000, first_name: Yohanes, ...]>
```
```ruby
user = MyQuery.user_by_email "yohanes@github.com"
user.id         # => 10000
user.first_name # => "Yohanes"
user.last_name  # => "Lumentut"
user.email      # => "yohanes@github.com"
```
### 3.6 List input (`@list`)
For an array consist list of inputs, we can use `fetch_list` method and `@list` pointer at the SQL statement.

```ruby
class MyQuery < Db2Query::Base
  query :user_by_ids, -> args {
    fetch_list("SELECT * FROM USERS WHERE ID IN (@list)", args)
  }
end
```
```bash
irb(main):007:0> MyQuery.user_by_ids [10000,10001,10002]
  SQL (2.8ms)  SELECT * FROM USERS WHERE ID IN ('10000', '10001', '10002')
=> #<Db2Query::Result [#<Record id: 10000, name: "Carol", last_name: "Danvers", email: "captain.marvel@marvel.universe.com">, #<Record id: 10001, first_name: "Natasha", last_name: "Romanova", email: "black.widow@marvel.universe">, #<Record id: 10002, first_name: "Wanda", last_name: "Maximoff", email: "scarlet.witch@marvel.universe.com">]>

```
```ruby
users = MyQuery.user_by_ids [10000,10001,10002]
user = users.first
user == users.record # => true

user.id         # => 10000
user.first_name # => "Carol"
user.last_name  # => "Danvers"
user.email      # => "captain.marvel@marvel.universe.com"
```

### 3.7 Formatter
For the latest version of **Db2Query**, there is no more **Db2Query::Formatter** class. We can implement our formater into **deserialize** method of our [**QueryDefinitions**](#32-querydefinitions).

If you upgrade from the previous version, you have to run **`rake db2query:init`** again to override the initializer. Please create a backup of your Formatter classes before you do this operation. Then you can implement your Formatter methods into your **QueryDefinitions**.

## 4. Available Result Object methods
`Db2Query::Result` inherit all `ActiveRecord::Result` methods with additional custom methods:
  1. `records` to convert query result into an array of Result query's Record objects.
  2. `record` to get the first Record Object of Result query.
  3. `to_h` to convert query result into an array of hashes with symbolized keys.

## 5. ActiveRecord Combination

Create an abstract class that inherits from `ActiveRecord::Base`. We have to implement `splat` operator correctly at the arguments to make it works.

```ruby
class Db2Record < ActiveRecord::Base
  self.abstract_class = true

  def self.query(sql, args)
    Db2Query::Base.query(sql, *args)
  end
end
```

Utilize the goodness of rails model `scope`
```ruby
class User < Db2Record
  scope :by_name, -> *args {
    query("SELECT * FROM USERS WHERE $first_name = ? AND $last_name = ?", args)
  }
end
```

```bash
User.by_name first_name: "Strange", last_name: "Stephen"
SQL Load (3.28ms)  SELECT * FROM USERS WHERE first_name = ? AND last_name = ? [["first_name", Strange], ["last_name", Stephen]]
=> [{:id=> 10000, :first_name=> "Strange", :last_name=> "Stephen", :email=> "strange@marvel.universe.com"}]
```

Another example:
```ruby
class User < Db2Record
  scope :age_gt, -> *args {
    query("SELECT * FROM USERS WHERE age > ?", args)
  }
end
```

```bash
User.age_gt 500
SQL Load (3.28ms)  SELECT * FROM USERS WHERE age > 500
=> [{:id=> 99999, :first_name=> "Ancient", :last_name=> "One", :email=> "ancientone@marvel.universe.com"}]
```

## 6. Examples

For complete examples please see the basic examples [here](https://github.com/yohaneslumentut/db2_query/blob/master/test/dummy/app/queries/user_query.rb).

## 7. License
The gem is available as open-source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
