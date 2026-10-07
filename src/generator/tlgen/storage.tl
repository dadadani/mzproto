entity#10000001 offset:int text:string = Entity;
metadata#10000002 flags:# active:flags.0?true note:flags.1?string entities:Vector<Entity> nested:vector<Vector<int>> count:int edited_at:long @since(2) = Metadata;
evolving#10000003 value:int tag:string @since(3) = Evolving;
holder#10000004 child:Evolving tail:int = Holder;
versionFlags#10000005 flags:# marked:flags.0?true @since(2) note:flags.1?string @since(2) extra_flags:# @since(3) extra:extra_flags.0?int @since(3) = VersionFlags;
versionTree#10000006 items:vector<evolving> child:evolving = VersionTree;
