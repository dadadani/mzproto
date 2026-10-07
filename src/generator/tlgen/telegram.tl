entity#10000001 offset:int text:string = Entity;
metadata#10000002 flags:# active:flags.0?true note:flags.1?string entities:Vector<Entity> nested:vector<Vector<int>> count:int bare:entity = Metadata;
empty#10000003 = Empty;
primitives#10000004 i:int l:long d:double big:int128 bigger:int256 boxed:Int yes:Bool bytes:bytes = Primitives;
shared#10000005 flags:# active:flags.1?true value:flags.1?int = Shared;
small#10000008 value:int = Choice;
wide#10000009 value:int256 = Choice;
holder#1000000a child:wide = Holder;
recursive#1000000b children:Vector<Recursive> child:wide = Recursive;
wideVector#1000000c values:vector<int256> = WideVector;
---functions---
get#10000006 = Metadata;
invoke#10000007 {X:Type} query:!X = X;
getNumber#1000000d = int;
getNumbers#1000000e = Vector<int>;
