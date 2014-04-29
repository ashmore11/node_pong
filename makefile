watch.client:
	coffee -wc -o public coffee/client.coffee

watch.server:
	coffee -wc -o public coffee/server.coffee

server:
	node public/server.js

pull:
	git pull origin master

push:
	git push origin master