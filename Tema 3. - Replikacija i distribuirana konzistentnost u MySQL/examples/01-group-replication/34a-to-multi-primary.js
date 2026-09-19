shell.connect({ host: '127.0.0.1', port: 3307, user: 'icadmin', password: 'IcAdmin#2026' });
var c = dba.getCluster();
c.switchToMultiPrimaryMode();
println(JSON.stringify(c.status(), null, 2));
