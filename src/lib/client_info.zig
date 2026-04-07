const std = @import("std");

const ClientInfo = @This();

api_id: u32,
api_hash: []const u8,

device_model: []const u8,
system_version: []const u8,
app_version: []const u8,
system_lang_code: []const u8,
lang_pack: []const u8,
lang_code: []const u8,

pub fn deinit(self: *ClientInfo, allocator: std.mem.Allocator) void {
    allocator.free(self.api_hash);
    allocator.free(self.device_model);
    allocator.free(self.system_version);
    allocator.free(self.app_version);
    allocator.free(self.system_lang_code);
    allocator.free(self.lang_pack);
    allocator.free(self.lang_code);
}
