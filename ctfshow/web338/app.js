var createError = require('http-errors');
var express = require('express');
var ejs = require('ejs');
var path = require('path');
var cookieParser = require('cookie-parser');
var logger = require('morgan');
var session = require('express-session');
var FileStore = require('session-file-store')(session);

var indexRouter = require('./routes/index');
var loginRouter = require('./routes/login');

var app = express();

//session
var identityKey = 'auth';
 
app.use(session({
  name: identityKey,
  secret: 'ctfshow_session_secret', 
  store: new FileStore(), 
  saveUninitialized: false, 
  resave: false,
  cookie: {
    maxAge: 60 * 60 * 1000 // 有效期，单位是毫秒
  }
}));

// view engine setup
app.set('views', path.join(__dirname, 'views'));
app.engine('html', require('ejs').__express); 
app.set('view engine', 'html');

app.use(logger('dev'));
app.use(express.json());
app.use(express.urlencoded({ extended: false }));
app.use(cookieParser());
app.use(express.static(path.join(__dirname, 'public')));

app.use('/', indexRouter);
app.use('/login', loginRouter);

// catch 404 and forward to error handler
app.use(function(req, res, next) {
  next(createError(404));
});

// error handler
app.use(function(err, req, res, next) {
  // set locals, only providing error in development
  res.locals.message = err.message;
  res.locals.error = req.app.get('env') === 'development' ? err : {};

  // render the error page
  res.status(err.status || 500);
  res.render('error');
});

module.exports = app;
