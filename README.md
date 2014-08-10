# Get started
To get dependencies, type `bundle install`.

Run the server using `bundle exec thin -R config.ru -p 9977 start`.

Run the migrations with `sequel -m migrations postgres://localhost:5432/training`. Create a new migration with `touch migrations/$(date +%s)_name_of_migration.rb`.


To install postgres, `brew install postgres` (OS X). Set up a db in the app root directory:
```bash
mkdir -p db/pg
initdb db/pg
createdb training
```

Run with:
```bash
postgres -D db/pg
```

Run memcached too (should be preinstalled on OS X):
```bash
memcached
```

Install `pygments`:
```
sudo pip install pygments
```

# Useful tools:
#### `pry`
Pry is a Ruby REPL. `bundle exec pry`.

#### `httpie`
HTTPie lets you easily test APIs from the command line. `sudo pip install httpie`.
