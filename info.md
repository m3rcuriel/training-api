## FAQ

Note: everything in here is meant to be run inside the `training-api` directory.

Note 2: before doing things, give yourself `lead` permissions:

```bash
gem install pry
pry
```

then in the ruby console that appears...

```ruby
Models::Users.where(email: 'demo@example.com').update(permissions: 'lead', time_updated: Time.now)
# should return `1` (number of database rows affected)
```

### How do I actually deploy to production?

Check out `aws/deploy-instructions.md` for a starting place

### How do I create new users?

Via web interface:

On the menu bar, there's a "add user" button.

Via command line:

```bash
pry
```

then

```ruby
# note: this is also how you'd insert users/etc in normal code
Models::Users.insert(key: value, key2: value)
```

### How do I create new badges?

Via web interface:

On the menu bar, there's an "add badge" button.

Via command line:

```bash
pry
```

```ruby
Models::Badges.insert(key: value, key2: value)
```

### How do I change a badge image?

- you'll have to do this every time your server restarts, as `export`-defined environment variables are discarded

1. stop the `thin` server from running
2. run the `export` commands under this list
3. start the `thin` server again

```bash
export AWS_ACCESS_KEY_ID=YOUR_KEY_ID_HERE
export AWS_SECRET_ACCESS_KEY=YOUR_SECRET_KEY_HERE
```

Now you should be able to change badge images by clicking on a badge, clicking "edit badge", then clicking on the badge image and following instructions presented.

You'll also have to define your S3 bucket policy. And probably change something in the web app.

...

Let me know when you reach here. ^_^

### How do I see the database schema?

```bash
psql training
```

then inside the postgres console, to see the `users` table schema (for instance)

```
\d users;
```

Normal SQL can also be run in here, so `SELECT * FROM users;` would generate a useful output.
