Random stuff: `training.svgxct.cfg.usw2.cache.amazonaws.com:11211` `training.cui9ng4dny4l.us-west-2.rds.amazonaws.com:5432`

---

Once ssh'd in:
```bash
sudo yum update

ssh-keygen -t rsa -C "you@example.com" # default file is fine, no passphrase
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_rsa
cat .ssh/id_rsa.pub # copy the output, paste into gitlabs under settings -> deploy key

sudo yum install git postgresql-devel nginx libcurl-devel.x86_64

git clone git@gitlab.com:loganh/training-api.git
cd training-api

gem install bundler
\curl -sSL https://get.rvm.io | bash
source /home/ec2-user/.rvm/scripts/rvm
rvm install ruby-2.1.1
bundle install

sequel -m migrations postgres://logan:Dj3AsZqAxG3h9x@training.cui9ng4dny4l.us-west-2.rds.amazonaws.com:5432/training
# until i get iam/ec2 creds autorotating...
export AWS_ACCESS_KEY_ID=YOUR_KEY_ID_HERE
export AWS_SECRET_ACCESS_KEY=YOUR_SECRET_KEY_HERE

thin -R config.ru -p 7000 -s 3 start
sudo nano /etc/nginx/nginx.conf # see below for what to put in
```

Your `nginx.conf` should mostly remain default, but scroll to `server` and add this stuff where applicable.
```
    upstream thin {
        server 127.0.0.1:7000;
        server 127.0.0.1:7001;
        server 127.0.0.1:7002;
    }

    server {
        ...
        server_name api.fremontrobotics.com;

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

Save and exit. Just a few more terminal commands...
```bash
sudo /usr/sbin/nginx -t
sudo /etc/init.d/nginx start
```

All done! If you need to change the config:
```bash
sudo /usr/sbin/nginx -t
sudo /usr/sbin/nginx -s reload
```
