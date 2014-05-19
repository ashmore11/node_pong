// Generated by CoffeeScript 1.7.1
(function() {
  var App, Timer,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  Timer = (function() {
    Timer.prototype.offset = null;

    Timer.prototype.clock = null;

    Timer.prototype.interval = null;

    Timer.prototype.delay = null;

    Timer.prototype.el = null;

    function Timer(element, delay) {
      this.update = __bind(this.update, this);
      this.el = element;
      this.delay = delay;
      this.reset();
    }

    Timer.prototype.start = function() {
      if (!this.interval) {
        this.offset = Date.now();
        return this.interval = setInterval(this.update, this.delay);
      }
    };

    Timer.prototype.stop = function() {
      if (this.interval) {
        clearInterval(this.interval);
        return this.interval = null;
      }
    };

    Timer.prototype.reset = function() {
      this.clock = 0;
      return this.render();
    };

    Timer.prototype.update = function() {
      this.clock += this.delta();
      return this.render();
    };

    Timer.prototype.render = function() {
      return this.el.html(this.clock / 1000);
    };

    Timer.prototype.delta = function() {
      var d, now;
      now = Date.now();
      d = now - this.offset;
      this.offset = now;
      return d;
    };

    return Timer;

  })();

  App = (function() {
    App.prototype.window = null;

    App.prototype.pong_stage = null;

    App.prototype.single_player = null;

    App.prototype.multiplayer = null;

    App.prototype.user_div = null;

    App.prototype.disconnect_div = null;

    App.prototype.player_1_score = null;

    App.prototype.player_2_score = null;

    App.prototype.socket = null;

    App.prototype.canvas = null;

    App.prototype.stage = null;

    App.prototype.images = null;

    App.prototype.title_view = null;

    App.prototype.total_loaded = 0;

    App.prototype.user_id = null;

    App.prototype.timer = null;

    App.prototype.score = 0;

    App.prototype.high_score = null;

    App.prototype.score_alert = null;

    App.prototype.x_speed = null;

    App.prototype.y_speed = null;

    App.prototype.single_player_mode = true;

    App.prototype.single_player_timer = null;

    App.prototype.paddle_1_disabled = false;

    App.prototype.paddle_2_disabled = false;

    App.prototype.player_limit = false;

    function App() {
      this.player_two_score = __bind(this.player_two_score, this);
      this.player_one_score = __bind(this.player_one_score, this);
      this.hide_title_view = __bind(this.hide_title_view, this);
      this.handle_load_complete = __bind(this.handle_load_complete, this);
      this.handle_file_load = __bind(this.handle_file_load, this);
      this.window = $(window);
      this.pong_stage = $('#PongStage');
      this.single_player = $('#single_player');
      this.multiplayer = $('#multiplayer');
      this.wait = $('#wait');
      this.max_users = $('#max_users');
      this.user_div = $('#user_div');
      this.disconnect_div = $('#disconnect_div');
      this.player_1_score = $('#player_1_score');
      this.player_2_score = $('#player_2_score');
      this.high_score = $('#high_score');
      this.score_alert = $('#score_alert');
      this.x_speed = 12;
      this.y_speed = 10;
      this.window.on('touchmove', function(event) {
        return event.preventDefault();
      });
      this.window.on('resize', this.on_resize());
      this.create_stage();
      this.multiplayer.on('click', (function(_this) {
        return function() {
          _this.single_player_mode = false;
          return _this.handle_users();
        };
      })(this));
      this.single_player.on('click', (function(_this) {
        return function() {
          _this.single_player_mode = true;
          _this.timer = new Timer($('#timer'), 10);
          return _this.hide_title_view();
        };
      })(this));
    }

    App.prototype.handle_users = function() {
      this.socket = io.connect('http://scott.local:3700');
      this.socket.on('connect', (function(_this) {
        return function() {
          _this.multiplayer.animate({
            opacity: 0
          }, function() {
            return $(this).hide();
          });
          _this.wait.animate({
            opacity: 1,
            marginTop: -95
          }, 1000);
          _this.socket.emit('adduser', prompt("What's your name?"));
          _this.socket.on('updateusers', function(user) {
            var html;
            _this.on_resize();
            html = user + ' has joined the game!';
            return _this.user_div.html(html).fadeIn(1000).delay(1000).fadeOut(1000, function() {
              return $(_this).html('');
            });
          });
          return _this.socket.on('user_disconnect', function(user) {
            var html;
            html = user + ' has disconnected...';
            return _this.disconnect_div.html(html).fadeIn(1000).delay(1000).fadeOut(1000, function() {
              return $(_this).html('');
            });
          });
        };
      })(this));
      this.socket.on('user_num', (function(_this) {
        return function(user_num) {
          if (user_num > 1) {
            _this.socket.emit('players_ready');
          }
          if (user_num < 2) {
            _this.reset_game();
            _this.pong_stage.animate({
              opacity: 1
            });
            _this.player_1_score.animate({
              opacity: 0
            });
            _this.player_2_score.animate({
              opacity: 0
            });
            _this.single_player.show(function() {
              return $(this).animate({
                opacity: 1
              });
            });
            return _this.wait.show(function() {
              return $(this).animate({
                opacity: 1
              });
            });
          }
        };
      })(this));
      this.socket.on('start_game', (function(_this) {
        return function(users) {
          return _this.players_ready(users);
        };
      })(this));
      this.socket.on('player_1_score', (function(_this) {
        return function() {
          return _this.player_one_score();
        };
      })(this));
      this.socket.on('player_2_score', (function(_this) {
        return function() {
          return _this.player_two_score();
        };
      })(this));
      this.socket.on('max_users', (function(_this) {
        return function(user) {
          return _this.too_many_users(user);
        };
      })(this));
      return this.socket.on('assign_user', (function(_this) {
        return function(i) {
          if (i === 0) {
            _this.paddle_2_disabled = true;
          } else {
            _this.paddle_2_disabled = false;
          }
          if (i === 1) {
            _this.paddle_1_disabled = true;
          } else {
            _this.paddle_1_disabled = false;
          }
          if (i > 1) {
            return _this.player_limit = true;
          } else {
            return _this.player_limit = false;
          }
        };
      })(this));
    };

    App.prototype.too_many_users = function(user) {
      this.wait.hide();
      return this.max_users.show().animate({
        opacity: 1
      });
    };

    App.prototype.create_stage = function() {
      var preloader;
      this.canvas = document.getElementById('PongStage');
      this.stage = new Stage(this.canvas);
      this.stage.canvas.width = this.window.width();
      this.stage.canvas.height = this.window.height();
      this.images = [
        {
          id: 'player_1',
          src: 'images/paddle.png'
        }, {
          id: 'player_2',
          src: 'images/paddle2.png'
        }, {
          id: 'ball',
          src: 'images/ball.png'
        }, {
          id: 'player_1_win',
          src: 'images/player_1_win.png'
        }, {
          id: 'player_2_win',
          src: 'images/player_2_win.png'
        }
      ];
      preloader = new PreloadJS();
      preloader.onFileLoad = this.handle_file_load;
      preloader.loadManifest(this.images);
      Ticker.setFPS(60);
      return Ticker.addListener(this.stage);
    };

    App.prototype.handle_file_load = function(e) {
      var img;
      switch (e.type) {
        case PreloadJS.IMAGE:
          img = new Image();
          img.src = e.src;
          img.onload = this.handle_load_complete();
          window[e.id] = new Bitmap(img);
          return this.handle_load_complete();
      }
    };

    App.prototype.handle_load_complete = function() {
      this.total_loaded++;
      if (this.images.length === this.total_loaded) {
        return this.add_title_view();
      }
    };

    App.prototype.add_title_view = function() {
      this.single_player.animate({
        opacity: 1
      });
      this.multiplayer.animate({
        opacity: 1
      });
      this.title_view = new Container();
      return this.stage.addChild(this.title_view);
    };

    App.prototype.players_ready = function(users) {
      this.player_1_score.find('.user').html(users[0] + ' - ');
      this.player_2_score.find('.user').html(' - ' + users[1]);
      return this.delay(1000, (function(_this) {
        return function() {
          return _this.hide_title_view();
        };
      })(this));
    };

    App.prototype.hide_title_view = function() {
      this.multiplayer.animate({
        opacity: 0
      }, function() {
        return $(this).hide();
      });
      this.wait.animate({
        opacity: 0
      }, function() {
        return $(this).hide();
      });
      this.single_player.animate({
        opacity: 0
      }, function() {
        return $(this).hide();
      });
      if (this.player_limit === false) {
        this.max_users.animate({
          opacity: 0
        }, function() {
          return $(this).hide();
        });
      }
      this.max_users.animate({
        top: this.window.height() - 15
      });
      if (this.title_view !== null) {
        Tween.get(this.title_view).to({
          y: -((this.window.height() / 2) + 45)
        }, 500);
      }
      return this.delay(500, (function(_this) {
        return function() {
          return _this.add_game_view();
        };
      })(this));
    };

    App.prototype.add_game_view = function() {
      var h, oh, ow, scale, w;
      this.pong_stage.css({
        opacity: 0
      });
      this.stage.removeChild(this.title_view);
      this.title_view = null;
      w = this.window.width() / 5;
      h = this.window.height() / 5;
      ow = 145;
      oh = 1129;
      scale = Math.min(w / ow, h / oh);
      player_1.scaleX = scale;
      player_1.scaleY = scale;
      player_1.x = 0;
      player_1.y = this.window.height() / 2;
      player_1.regY = player_1.image.height / 2;
      player_2.scaleX = scale;
      player_2.scaleY = scale;
      player_2.x = this.window.width() - (player_2.image.width * scale);
      player_2.y = this.window.height() / 2;
      player_2.regY = player_2.image.height / 2;
      w = this.window.width() / 10;
      h = this.window.height() / 10;
      ow = 245;
      oh = 400;
      scale = Math.min(w / ow, h / oh);
      ball.scaleX = scale;
      ball.scaleY = scale;
      ball.x = this.window.width() / 2;
      ball.y = this.window.height() / 2;
      ball.regX = ball.image.width / 2;
      ball.regY = ball.image.height / 2;
      if (this.single_player_mode === false) {
        this.player_1_score.animate({
          opacity: 1
        });
        this.player_2_score.animate({
          opacity: 1
        });
        this.player_1_score.css({
          left: (this.window.width() / 2) - 315
        });
        this.player_2_score.css({
          left: (this.window.width() / 2) + 15
        });
      }
      this.stage.addChild(player_1, player_2, ball);
      this.pong_stage.animate({
        opacity: 1
      }, 500);
      if (this.single_player_mode === false) {
        this.move_paddles();
      }
      this.paddle_events();
      return this.trigger_game();
    };

    App.prototype.trigger_game = function() {
      ball.onPress = (function(_this) {
        return function() {
          if (_this.single_player_mode) {
            return _this.start_game();
          } else {
            return _this.socket.emit('ball_pressed');
          }
        };
      })(this);
      if (this.single_player_mode === false) {
        return this.socket.on('game_started', (function(_this) {
          return function() {
            return _this.start_game();
          };
        })(this));
      }
    };

    App.prototype.paddle_events = function() {
      if (this.player_limit === false) {
        return this.window.on('touchstart touchmove mousedown mousemove', (function(_this) {
          return function(event) {
            var page_x, page_y, percent;
            page_y = event.originalEvent.pageY;
            page_x = event.originalEvent.pageX;
            percent = (page_y / _this.window.height()) * 100;
            if (_this.single_player_mode) {
              return _this.single_player_paddle(page_y);
            } else {
              if (_this.paddle_1_disabled === false) {
                _this.socket.emit('move_1', percent);
              }
              if (_this.paddle_2_disabled === false) {
                return _this.socket.emit('move_2', percent);
              }
            }
          };
        })(this));
      }
    };

    App.prototype.move_paddles = function() {
      var h, oh, ow, scale, w;
      w = this.window.width() / 5;
      h = this.window.height() / 5;
      ow = 145;
      oh = 1129;
      scale = Math.min(w / ow, h / oh);
      this.socket.on('paddle_1', (function(_this) {
        return function(percent) {
          var bottom, page_y, top;
          page_y = (percent / 100) * _this.window.height();
          player_1.y = page_y;
          bottom = _this.window.height() - (player_1.image.height * scale) / 2;
          top = (player_1.image.height * scale) / 2;
          if (player_1.y >= bottom) {
            player_1.y = bottom;
          }
          if (player_1.y <= top) {
            return player_1.y = top;
          }
        };
      })(this));
      return this.socket.on('paddle_2', (function(_this) {
        return function(percent) {
          var bottom, page_y, top;
          page_y = (percent / 100) * _this.window.height();
          player_2.y = page_y;
          bottom = _this.window.height() - (player_2.image.height * scale) / 2;
          top = (player_2.image.height * scale) / 2;
          if (player_2.y >= bottom) {
            player_2.y = bottom;
          }
          if (player_2.y <= top) {
            return player_2.y = top;
          }
        };
      })(this));
    };

    App.prototype.single_player_paddle = function(page_y) {
      var bottom, h, oh, ow, scale, top, w;
      w = this.window.width() / 5;
      h = this.window.height() / 5;
      ow = 145;
      oh = 1129;
      scale = Math.min(w / ow, h / oh);
      player_1.y = page_y;
      bottom = this.window.height() - (player_1.image.height * scale) / 2;
      top = (player_1.image.height * scale) / 2;
      if (player_1.y >= bottom) {
        player_1.y = bottom;
      }
      if (player_1.y <= top) {
        return player_1.y = top;
      }
    };

    App.prototype.start_game = function() {
      if (this.single_player_mode) {
        this.timer.start();
        this.single_player_timer = setInterval((function(_this) {
          return function() {
            return _this.single_player_update();
          };
        })(this), 15);
      } else {
        this.tween_ball();
        this.socket.on('ballmove', (function(_this) {
          return function(x, y) {
            ball.x = (x / 100) * _this.window.width();
            return ball.y = (y / 100) * _this.window.height();
          };
        })(this));
      }
      return Tween.get(ball, {
        loop: true
      }).to({
        rotation: 360
      }, 1000);
    };

    App.prototype.tween_ball = function() {
      this.socket.on('paddle_hit', function() {
        Tween.removeTweens(ball);
        return Tween.get(ball, {
          loop: true
        }).to({
          rotation: 360
        }, 1000);
      });
      return this.socket.on('wall_hit', function() {
        Tween.removeTweens(ball);
        return Tween.get(ball, {
          loop: true
        }).to({
          rotation: -360
        }, 1000);
      });
    };

    App.prototype.player_one_score = function() {
      Tween.removeTweens(ball);
      Tween.get(ball).to({
        rotation: 0
      }, 1);
      this.player_1_score.find('.score').html(parseInt(this.player_1_score.find('.score').html()) + 1);
      ball.x = this.window.width() / 2;
      ball.y = this.window.height() / 2;
      ball.regX = ball.image.width / 2;
      ball.regY = ball.image.height / 2;
      if (this.player_1_score.find('.score').html() === '3') {
        player_1_win.x = (this.window.width() / 2) - 100;
        player_1_win.y = this.window.height() / 2;
        this.stage.addChild(player_1_win);
        Tween.get(player_1_win).to({
          y: (this.window.height() / 2) - 45
        }, 500);
        return this.reset_game();
      }
    };

    App.prototype.player_two_score = function() {
      Tween.removeTweens(ball);
      Tween.get(ball).to({
        rotation: 0
      }, 1);
      ball.x = this.window.width() / 2;
      ball.y = this.window.height() / 2;
      if (this.single_player_mode) {
        clearInterval(this.single_player_timer);
        this.single_player_timer = null;
        this.single_player_score($('#timer').html());
        this.timer.stop();
        return this.timer.reset();
      } else {
        this.player_2_score.find('.score').html(parseInt(this.player_2_score.find('.score').html()) + 1);
        if (this.player_2_score.find('.score').html() === '3') {
          player_2_win.x = (this.window.width() / 2) - 100;
          player_2_win.y = this.window.height() / 2;
          this.stage.addChild(player_2_win);
          Tween.get(player_2_win).to({
            y: (this.window.height() / 2) - 45
          }, 500);
          return this.reset_game();
        }
      }
    };

    App.prototype.single_player_score = function(score) {
      var html;
      if (score > this.score) {
        this.high_score.html('HIGH SCORE: ' + score + ' SECONDS');
        html = 'NEW HIGH SCORE!';
      } else {
        this.high_score.html('HIGH SCORE: ' + this.score + ' SECONDS');
        html = 'YOU SUCK!';
      }
      this.score_alert.html(html).fadeIn(1000).delay(2500).fadeOut(1000, (function(_this) {
        return function() {
          return $(_this).html('');
        };
      })(this));
      return this.score = score;
    };

    App.prototype.reset_game = function() {
      if (this.single_player_mode === false) {
        this.player_1_score.find('.score').html('0');
        this.player_2_score.find('.score').html('0');
        player_1_win.onPress = (function(_this) {
          return function() {
            return _this.socket.emit('remove_win');
          };
        })(this);
        this.socket.on('remove', function() {
          return Tween.get(player_1_win).to({
            y: -115
          }, 300);
        });
        player_2_win.onPress = (function(_this) {
          return function() {
            return _this.socket.emit('remove_win');
          };
        })(this);
        this.socket.on('remove', function() {
          return Tween.get(player_2_win).to({
            y: -115
          }, 300);
        });
      }
      return ball.onPress = (function(_this) {
        return function() {
          if (_this.single_player_mode) {
            return _this.start_game();
          } else {
            return _this.socket.emit('ball_pressed');
          }
        };
      })(this);
    };

    App.prototype.increase_speed = function(axis) {
      var speed;
      speed = Math.floor((axis * -1.02) * 100) / 100;
      return speed;
    };

    App.prototype.single_player_update = function() {
      var ball_h, ball_height, ball_oh, ball_ow, ball_scale, ball_w, ball_width, player_h, player_height, player_oh, player_ow, player_scale, player_w, player_width;
      ball.x = ball.x + this.x_speed;
      ball.y = ball.y + this.y_speed;
      player_2.y = ball.y;
      player_w = this.window.width() / 5;
      player_h = this.window.height() / 5;
      player_ow = 145;
      player_oh = 1129;
      player_scale = Math.min(player_w / player_ow, player_h / player_oh);
      player_width = player_1.image.width * player_scale;
      player_height = player_1.image.height * player_scale;
      ball_w = this.window.width() / 10;
      ball_h = this.window.height() / 10;
      ball_ow = 245;
      ball_oh = 400;
      ball_scale = Math.min(ball_w / ball_ow, ball_h / ball_oh);
      ball_width = ball.image.width * ball_scale;
      ball_height = ball.image.height * ball_scale;
      if (ball.y <= ball_width / 2) {
        this.y_speed = this.increase_speed(this.y_speed);
        Tween.removeTweens(ball);
        Tween.get(ball, {
          loop: true
        }).to({
          rotation: -360
        }, 1000);
      }
      if (ball.y >= this.window.height() - (ball_width / 2)) {
        this.y_speed = this.increase_speed(this.y_speed);
        Tween.removeTweens(ball);
        Tween.get(ball, {
          loop: true
        }).to({
          rotation: -360
        }, 1000);
      }
      if (ball.x < player_width + (ball_width / 2) && ball.y > player_1.y - player_height / 2 && ball.y < player_1.y + (player_height / 2)) {
        this.x_speed = this.increase_speed(this.x_speed);
        Tween.removeTweens(ball);
        Tween.get(ball, {
          loop: true
        }).to({
          rotation: 360
        }, 1000);
      }
      if (ball.x > this.window.width() - (player_width + (ball_width / 2)) && ball.y > player_2.y - (player_height / 2) && ball.y < player_2.y + (player_height / 2)) {
        this.x_speed = this.increase_speed(this.x_speed);
        Tween.removeTweens(ball);
        Tween.get(ball, {
          loop: true
        }).to({
          rotation: 360
        }, 1000);
      }
      if (ball.x < player_width) {
        if (this.y_speed < 0) {
          this.y_speed = 10;
        } else {
          this.y_speed = -10;
        }
        this.x_speed = 12;
        return this.player_two_score();
      }
    };

    App.prototype.delay = function(time, fn, args) {
      return setTimeout(fn, time, args);
    };

    App.prototype.on_resize = function() {
      return $('body').animate({
        scrollTop: 0
      }, 10);
    };

    return App;

  })();

  $(function() {
    var app;
    return app = new App;
  });

}).call(this);
