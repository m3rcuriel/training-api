training.svgxct.cfg.usw2.cache.amazonaws.com:11211
training.cui9ng4dny4l.us-west-2.rds.amazonaws.com:5432

sudo su
sudo yum update
ssh-keygen -t rsa -C "you@example.com"
[default file is fine, no passphrase]
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_rsa
cat .ssh/id_rsa.pub
[copy that value, paste into gitlabs where required]
sudo yum install git postgresql-devel
git clone git@gitlab.com:loganh/training-api.git
[paste the above into the config/live/....yml which they should be in]
cd training-api
gem install bundler
\curl -sSL https://get.rvm.io | bash
rvm install ruby-2.1.1
bundle install
sequel -m migrations postgres://logan:Dj3AsZqAxG3h9x@training.cui9ng4dny4l.us-west-2.rds.amazonaws.com:5432/training
thin -R config.ru -p 7000 -s 3 start
sudo yum install nginx
^ starts thin with 3 workers at 7000, 7001, 7002
sudo nano /etc/nginx/nginx.conf:
```
    upstream thin {
        server 127.0.0.1:7000;
        server 127.0.0.1:7001;
        server 127.0.0.1:7002;
    }

    server {
        ...
        server_name api.oflogan.com;

        location / {
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header Host $http_host;
            proxy_redirect off;
            proxy_next_upstream error;

            if ($http_x_forwarded_proto != "https") {
                return 301 https://$host$request_uri;
            }

            proxy_pass http://thin;
        }
    }
```

sudo /usr/sbin/nginx -t
sudo /usr/sbin/nginx -s reload
