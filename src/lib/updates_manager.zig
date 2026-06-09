const std = @import("std");
const bapi = @import("mzproto_bridge");

const UpdatesManager = @This();

// for now this enough, but... TODO: maybe a dynamic buffer?
pub const BUFFER_SIZE = 30;

buffer: [BUFFER_SIZE]bapi.Update,
updates_queue: std.Io.Queue(bapi.Update),

pub fn init(self: *UpdatesManager) void {
    self.updates_queue = .init(&self.buffer);
}

pub fn deinit(self: *UpdatesManager, allocator: std.mem.Allocator, io: std.Io) void {

    self.updates_queue.close(io);

    var buffer: [BUFFER_SIZE]bapi.Update = undefined;
    const len = self.updates_queue.getUncancelable(io, &buffer, 0) catch {
        return;
    };
    for (0..len) |i| {
        buffer[i].deinit(allocator);
    }
}
