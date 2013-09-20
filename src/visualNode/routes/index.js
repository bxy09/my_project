
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