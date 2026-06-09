const std = @import("std");
const bapi = @import("mzproto_bridge");

pub fn clientStatusToUpdate(allocator: std.mem.Allocator, status: bapi.ClientStatus) !bapi.Update {
    var update_status = try bapi.UpdateClientStatus.init(allocator);
    errdefer update_status.deinit(allocator);

    try update_status.toRef().setStatus(allocator, status);

    var update = try bapi.Update.init(allocator);
    errdefer update.deinit(allocator);
    try update.toRef().setUpdateClientStatus(allocator, update_status);

    return update;
}
