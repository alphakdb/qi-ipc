.qi.import`event

\d .ipc

conns:1!flip`name`fullname`proc`stackname`port`handle`pid`lasthearbeat`error!"ssssiiip*"$\:()
connx:{[name;tmout] if[null(e:conns name)`handle;conns[name]:e,:`handle`error!tryconnectx[e`port;tmout]];e`handle}
conn:connx[;.conf.CONN_TIMEOUT]
tryconnectx:{[addr;tmout] 1_.qi.try[hopen;(hostport addr;tmout);0Ni]}
tryconnect:{[addr] tryconnectx[addr;.conf.CONN_TIMEOUT]}
pc:{
  if[count c:select from .ipc.conns where handle=x;
    if[count subs:.proc.self.subscribe_to;
      if[count fatal:select from c where name in key subs;
        show fatal;
        .qi.fatal"Lost vital connection. Exiting"]];
    `.ipc.conns upsert update handle:0Ni,pid:0Ni,lasthearbeat:0Np from c];
  }
  
hostport:{`$$[":"=f:first a:.qi.tostr x;a;f in .Q.n;"::",a;":",a]}

/ if .conf.MAX_CONNS>0, only open that many, and close after using
ping:{[names;x]
  if[mc:.qi.getconf[`MAX_CONNS;0];
    if[(rem:mc-count .z.W)<count names;
      :.z.s[;x]each rem cut names]];
  if[count err:select from(a:([]name:(),names)#conns)where null port;
    show err;
    '".ipc.ping - entries not found in .ipc.conns"];
  tmout:.conf.PING_TIMEOUT;
  c:$[mc;
    exec name!(.ipc.tryconnectx[;.conf.PING_TIMEOUT]each port)[;0]from a;
    exec name!.ipc.connx[;tmout]each name from a];
  if[count nc:where null c;.qi.info".ipc.ping - could not connect to ",","sv string nc];
  neg[h:c where not null c]@\:x;
  neg[h]@\:(::);
  if[mc;hclose each h];
  }

`conns upsert enlist`name`stackname`fullname`proc`port!(4#`hub),.conf.HUB_PORT;

\d .

.event.addhandler[`.z.pc;`.ipc.pc]