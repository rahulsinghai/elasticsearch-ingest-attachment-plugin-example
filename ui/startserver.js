var sys = require('sys')
var exec = require('child_process').exec;
function puts(error, stdout, stderr) { sys.puts(stdout) }
exec("~/npm/lib/node_modules/http-server/bin/http-server -a hostname.com -p 3000 -d false", puts);