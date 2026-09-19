shell.connect({ host: '127.0.0.1', port: 3307, user: 'icadmin', password: 'IcAdmin#2026' });
var c = dba.getCluster();
c.switchToSinglePrimaryMode({ host: '127.0.0.1', port: 3307, user: 'icadmin', password: 'IcAdmin#2026' });
var s = c.status();
println('primary = ' + s.defaultReplicaSet.primary + ' ; mode = ' + s.defaultReplicaSet.topologyMode + ' ; ' + s.defaultReplicaSet.statusText);
