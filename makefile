# install all dependencies
setup:
	npm install

# compile client side coffeescript and add to public directory
watch.client:
	coffee -wc -o public coffee/client.coffee

# compile server side coffeescript and add to public directory
watch.server:
	coffee -wc -o public coffee/server.coffee

# start running the server
server:
	node public/server.js

pull:
	git pull origin master

push:
	git push origin master