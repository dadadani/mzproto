entity#10000001 offset:int text:string = Entity;
metadata#10000002 flags:# active:flags.0?true note:flags.1?string entities:Vector<Entity> nested:vector<Vector<int>> count:int = Metadata;
evolving#10000003 value:int = Evolving;
holder#10000004 child:Evolving tail:int = Holder;
