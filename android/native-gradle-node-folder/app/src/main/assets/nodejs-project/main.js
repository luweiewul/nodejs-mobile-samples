var http = require('http');
//var leftPad = require('left-pad');
var versions_server = http.createServer( (request, response) => {
  var sqlite3 = require('sqlite3').verbose();
  var db = new sqlite3.Database(':memory:');

  db.serialize(function() {
    db.run("CREATE TABLE lorem (info TEXT)");

    var stmt = db.prepare("INSERT INTO lorem VALUES (?)");
    for (var i = 0; i < 10; i++) {
        stmt.run("Ipsum " + i);
    }
    stmt.finalize();

    db.all("SELECT rowid AS id, info FROM lorem", function(err, rows) {
      var result = '';
      rows.forEach((row) =>
        result += row.id + ": " + row.info + "\n"
      );
      response.end('Versions: ' + JSON.stringify(process.versions)+ ' sqlite3 SELECT result:'+result);
    });

  });

  db.close();
  
  //response.end('Versions: ' + JSON.stringify(process.versions) + ' left-pad: ' + leftPad(42, 5, '0'));
});
versions_server.listen(3000);
console.log('The node project has started.');
