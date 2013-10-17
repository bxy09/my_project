var http = require('http');
/*
 * GET home page.
 */

exports.index = function (req, res) {
  "use strict";
  res.render('index', { title: 'Express' });
};

exports.sar = function (req, res) {
  "use strict";
  res.send("nothing");
};

exports.db = function (req, res) {
  "use strict";
  var key;
  var querys = [];
  for (key in req.query) {
    querys.push(key + "=" + encodeURI(req.query[key]));
  }
  var queryString = querys.reduce(function (a, b) {return a + '&' + b; });
  var path = '/' + req.params[0] + '?' + queryString;
  var options = {
    host: '166.111.69.71',
    port: 27080,
    path: path
  };
  res.set('Content-Type', 'application/json');
  http.get(options, function (resq) {
    resq.on('data', function (chunk) {
      console.log('' + chunk);
      res.send('' + chunk);
    });
  });
};
