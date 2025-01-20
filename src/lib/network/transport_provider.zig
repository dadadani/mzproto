const std = @import("std");

pub const ConnectionEvent = @import("network_data_provider.zig").ConnectionEvent;

pub const SendFn = fn (*anyopaque, []const u8) void;
pub const RecvDataCallback = fn ([]u8, ?*const anyopaque) void;
pub const RecvEventCallback = fn (ConnectionEvent, ?*const anyopaque) void;
pub const SetRecvDataCallback = fn (*anyopaque, *const RecvDataCallback) void;
pub const SetRecvEventCallback = fn (*anyopaque, *const RecvEventCallback) void;
pub const SetUserDataFn = fn (*anyopaque, ?*const anyopaque) void;
pub const SetConnectionInfoFn = fn (*anyopaque, ConnectionInfo) void;

pub const ConnectionInfo = struct {
    dcId: u8,
    testMode: bool,
    media: bool,
    address: std.net.Address,
};

/// An interface for receiving and sending data to lower transport layers.
///
/// This is the actual interface that should be passed when using the main library.
pub const TransportProvider = struct {
    ptr: *anyopaque,

    vtable: struct {
        sendData: *const SendFn,
        setRecvDataCallback: *const SetRecvDataCallback,
        setRecvEventCallback: *const SetRecvEventCallback,
        setUserData: *const SetUserDataFn,
        setConnectionInfo: *const SetConnectionInfoFn,
    },

    pub inline fn sendData(self: TransportProvider, data: []const u8) void {
        return self.vtable.sendData(self.ptr, data);
    }

    pub inline fn setRecvDataCallback(self: TransportProvider, func: *const RecvDataCallback) void {
        return self.vtable.setRecvDataCallback(self.ptr, func);
    }

    pub inline fn setRecvEventCallback(self: TransportProvider, func: *const RecvEventCallback) void {
        return self.vtable.setRecvEventCallback(self.ptr, func);
    }

    pub inline fn setUserData(self: TransportProvider, ptr: ?*const anyopaque) void {
        return self.vtable.setUserData(self.ptr, ptr);
    }

    pub inline fn setConnectionInfo(self: TransportProvider, info: ConnectionInfo) void {
        return self.vtable.setConnectionInfo(self.ptr, info);
    }
};
