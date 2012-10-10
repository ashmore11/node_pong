// Generated by CoffeeScript 1.3.3
(function() {
  var app, express, io, usernames;

  express = require("express");

  app = express();

  io = require("socket.io").listen(8080);

  app.get("/", function(req, res) {
    return res.sendfile(__dirname + "/index.html");
  });

  usernames = {};

  io.sockets.on("connection", function(socket) {
    console.log('Connected, Backend');
    return socket.on("adduser", function(username) {
      socket.username = username;
      usernames[username] = username;
      socket.emit("updatepong", "SERVER", "you have connected");
      return io.sockets.emit("updateusers", usernames);
    });
  });

}).call(this);
