const std = @import("std");
const c = @import("cursor.zig");
const Error = c.Error;

pub const Message = struct {
    msg_id: u64,
    seqno: u32,
    body: []const u8,
    pub fn read(r: *c.Deserializer) Error!Message {
        const id = try r.long();
        const seqno = try r.int();
        const len = try r.int();
        if (len % 4 != 0) return error.InvalidData;
        return .{ .msg_id = id, .seqno = seqno, .body = try r.take(len) };
    }
    pub fn write(self: Message, w: *c.Serializer) Error!void {
        if (self.body.len % 4 != 0) return error.InvalidData;
        try w.long(self.msg_id);
        try w.int(self.seqno);
        try w.int(try c.count(self.body.len));
        try w.raw(self.body);
    }
};

pub const MessageContainer = struct {
    pub const id: u32 = 0x73f1f8dc;
    pub const View = struct {
        input: []const u8,
        count: u32,
        pub fn iterator(self: View) Iterator {
            return .{ .reader = .init(self.input), .remaining = self.count };
        }
        pub fn validateAll(self: View) Error!void {
            var it = self.iterator();
            while (try it.next()) |_| {}
        }
    };

    pub const Iterator = struct {
        reader: c.Deserializer,
        remaining: u32,
        pub fn next(self: *Iterator) Error!?Message {
            if (self.remaining == 0) {
                try self.reader.finish();
                return null;
            }
            const value = try Message.read(&self.reader);
            self.remaining -= 1;
            if (self.remaining == 0) try self.reader.finish();
            return value;
        }
    };

    pub fn view(input: []const u8) Error!View {
        var r = c.Deserializer.init(input);
        try r.expectId(id);
        const n = try r.int();
        if (n > 1024 or n > r.remaining() / 16) return error.InvalidData;
        return .{ .input = try r.take(r.remaining()), .count = n };
    }

    pub fn write(messages: []const Message, w: *c.Serializer) Error!void {
        if (messages.len > 1024) return error.InvalidData;
        try w.int(id);
        try w.int(try c.count(messages.len));
        for (messages) |message| try message.write(w);
    }

    pub fn serializedSize(messages: []const Message) Error!usize {
        var w = c.Serializer.measuring();
        try write(messages, &w);
        return w.position;
    }

    pub fn serialize(messages: []const Message, out: []u8) Error![]const u8 {
        var w = c.Serializer.init(out);
        try write(messages, &w);
        return w.out();
    }
};

pub const RpcResult = struct {
    pub const id: u32 = 0xf35c6d01;
    req_msg_id: u64,
    body: []const u8,
    pub fn view(input: []const u8) Error!RpcResult {
        var r = c.Deserializer.init(input);
        try r.expectId(id);
        const req = try r.long();
        if (r.remaining() % 4 != 0) return error.InvalidData;
        return .{ .req_msg_id = req, .body = try r.take(r.remaining()) };
    }
    pub fn write(self: RpcResult, w: *c.Serializer) Error!void {
        if (self.body.len % 4 != 0) return error.InvalidData;
        try w.int(id);
        try w.long(self.req_msg_id);
        try w.raw(self.body);
    }
    pub fn serializedSize(self: RpcResult) Error!usize {
        var w = c.Serializer.measuring();
        try self.write(&w);
        return w.position;
    }
    pub fn serialize(self: RpcResult, out: []u8) Error![]const u8 {
        var w = c.Serializer.init(out);
        try self.write(&w);
        return w.out();
    }
};

pub fn IdentifyFn(comptime TL: type) type {
    @setEvalBranchQuota(20_000_000);
    const object = @typeInfo(TL.AnyObject).@"union";
    const names = blk: {
        var fields: [object.field_names.len + 2][:0]const u8 = undefined;
        fields[0] = "rpcResult";
        fields[1] = "messageContainer";
        inline for (object.field_names, 0..) |name, i| fields[i + 2] = name;
        break :blk fields;
    };
    const values = blk: {
        var fields: [object.field_names.len + 2]u32 = undefined;
        fields[0] = RpcResult.id;
        fields[1] = MessageContainer.id;
        inline for (object.field_types, 0..) |Field, i| {
            fields[i + 2] = @typeInfo(Field).pointer.child.tl_id;
        }
        break :blk fields;
    };

    return struct {
        pub const Identification = @Enum(u32, .exhaustive, &names, &values);

        pub fn identify(input: []const u8) ?Identification {
            if (input.len < @sizeOf(u32)) return null;
            return identifyId(std.mem.readInt(u32, input[0..4], .little));
        }

        pub fn identifyId(id: u32) ?Identification {
            if (id == RpcResult.id) return .rpcResult;
            if (id == MessageContainer.id) return .messageContainer;

            @setEvalBranchQuota(20_000_000);
            inline for (object.field_names, object.field_types) |name, Field| {
                const C = @typeInfo(Field).pointer.child;
                if (id == C.tl_id) {
                    return @field(Identification, name);
                }
            }
            return null;
        }
    };
}
