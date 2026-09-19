shell.options['useWizards'] = false;
function cd(p) { return { host: '127.0.0.1', port: p, user: 'icadmin', password: 'IcAdmin#2026' }; }
var s = mysql.getClassicSession(cd(3307));
s.runSql("DROP TABLE IF EXISTS poliklinika.no_pk_demo");
s.runSql("CREATE TABLE poliklinika.no_pk_demo (naziv VARCHAR(40) NOT NULL, iznos INT NOT NULL) ENGINE=InnoDB");
println('=== a PK-less InnoDB table now exists; ask the AdminAPI whether the instance is cluster-ready');
var r = dba.checkInstanceConfiguration(cd(3307));
println(JSON.stringify(r, null, 2));
s.runSql("DROP TABLE poliklinika.no_pk_demo");
println('=== and with it dropped again');
println(JSON.stringify(dba.checkInstanceConfiguration(cd(3307)), null, 2));
