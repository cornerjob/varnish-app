require
var express = require("express");
var log4js = require("log4js");

var app = express();
var logger = log4js.getLogger('Server');

app.get('/test', function(req, res){
    logger.info("###### [GET] BACKEND HIT");
    res.send("blah blah blah");
});

app.post('/test', function(req, res){
    logger.info("###### [POST] BACKEND HIT");
    res.send(JSON.stringify({a:"a", b:"b", c:"c"}));
});

app.listen(3000, function () {
    logger.info('Server started.  Listening on port 3000...');
});
