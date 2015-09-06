# Dev environment for training api

Currently these instructions are for Mac OS X only. GNU/Linux users should be able to follow along pretty easily, generally replacing `brew` with `apt-get`/`yum`/etc. Both GNU/Linux and OS X have the unix-nature.

## Install homebrew
Open Terminal.app. Download and install homebrew (instructions from [brew.sh](http://brew.sh/)):
```bash
ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
```

Make sure that you (1) follow all instructions and (2) do
```bash
brew doctor # check for postinstall problems
brew update # get notified of new packages
brew upgrade # download and install outdated packages
```

## Install git & python
```bash
brew install git python
```

## Install rvm

```bash
\curl -sSL https://get.rvm.io | bash -s stable
# read the postinstall message VERY CAREFULLY and follow what it says to do
```

This will install `rvm`, which stands for "ruby version manager".

Next, install the Ruby version that we use and create a gemset for robotics:
```bash
rvm install ruby 2.1.3
rvm use --default 2.1.3 # remove --default if you don't want it to be default
rvm gemset create firebots
rvm gemset use firebots
```

###### Important Note: Ruby 2.1.3 is the only version of Ruby that works with this project.

## Clone the project

If you don't already have one, follow [these instructions](https://help.github.com/articles/generating-ssh-keys/) to generate an ssh key.
However, replace steps 3 and 4 with: go to https://gitlab.com/profile/keys/new to add a new ssh key. Title it whatever.
Type `cat ~/.ssh/id_rsa.pub` and paste the output of that command into the "key" field of the new ssh key screen.

I recommend making a folder under your home directory called "robotics" and cloning this project within the robotics folder. Better to keep all the robotics stuff in one place.
```bash
# if you don't have access, contact Logan
git clone git@github.com:glinia/training-api.git
cd training-api
```

## Ubuntu only

```bash
sudo apt-get install libcurl4-openssl-dev
sudo apt-get install libpq-dev postgres-xc-client postgres-xc
```

## Create database

```bash
brew install postgresql
# MAKE SURE you follow all postinstall instructions before moving on

mkdir -p db/pg
initdb db/pg
createdb training
```

## Install dependencies

```bash
gem install bundler
bundle install
```

## Run migrations, start database, start cache

In another tab/window...
```bash
# run migrations (create database structure)
sequel -m migrations postgres://localhost:5432/training
postgres -D db/pg # start server
```

In yet another tab/window...
```bash
memcached # start the cache
```

## Make dev server

In your original tab/window...
```bash
thin -R config.ru -p 9977 start
```

You should now be able to go to `localhost:9977` in your browser and see a JSON message: `{"status":404,"message":"Not found!"}`.

**Note: you will have to quit and restart the server every time you make a code change to the api. This doesn't happen often so there is no automatic rebuild like there is for the web app.**
