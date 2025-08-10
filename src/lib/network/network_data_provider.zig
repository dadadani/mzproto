//   Copyright (c) 2025 Daniele Cortesi <https://github.com/dadadani>
//
//   Licensed under the Apache License, Version 2.0 (the "License");
//   you may not use this file except in compliance with the License.
//   You may obtain a copy of the License at
//
//       http://www.apache.org/licenses/LICENSE-2.0
//
//   Unless required by applicable law or agreed to in writing, software
//   distributed under the License is distributed on an "AS IS" BASIS,
//   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//   See the License for the specific language governing permissions and
//   limitations under the License.

const ConnectionInfo = @import("transport_provider.zig").ConnectionInfo;
const TransportEvent = @import("transport_provider.zig").TransportEvent;

pub const RecvFn = fn (*anyopaque, []const u8) anyerror!void;
pub const SuggestedRecvSizeFn = fn (*anyopaque) usize;
pub const SetUserDataFn = fn (*anyopaque, ?*const anyopaque) void;
pub const SendCallbackFn = fn (?[]const u8, ?*const anyopaque) void;
pub const SetSendCallbackFn = fn (*anyopaque, *const SendCallbackFn) void;
pub const SendEventFn = fn (*anyopaque, ConnectionEvent) void;
pub const GetConnectionDetailsFn = fn (*anyopaque) ConnectionInfo;

pub const RecvEventCallback = fn (TransportEvent, ?*const anyopaque) void;
pub const SetRecvEventCallback = fn (*anyopaque, *const RecvEventCallback) void;

pub const ConnectionEvent = enum {
    ConnectError,
    Connected,
    Disconnected,
};

/// An interface for receiving and sending data to the underlying network layer.
///
/// Ideally, you should implement the actual MTProto transport protocol (eg. Abridged), and then pass this interface to the actual network layer (TCP/UDP/Websocket/..).
///
/// Callbacks are used so that you can also provide asynchronous functions provided by event loops.
pub const NetworkDataProvider = struct {
    ptr: *anyopaque,

    vtable: struct {
        recvFn: *const RecvFn,
        suggestedRecvSizeFn: *const SuggestedRecvSizeFn,
        setUserDataFn: *const SetUserDataFn,
        setSendCallbackFn: *const SetSendCallbackFn,
        setRecvEventCallback: *const SetRecvEventCallback,
        sendEventFn: *const SendEventFn,
        getConnectionDetails: *const GetConnectionDetailsFn,
    },

    /// Sends data to the upper transport layer.
    ///
    /// When using this function, it is guaranteed that all of the data will be read by the upper layer.
    pub inline fn recv(self: NetworkDataProvider, src: []const u8) anyerror!void {
        return self.vtable.recvFn(self.ptr, src);
    }

    /// Asks the upper layer ideally how much data it should read.
    ///
    /// Note: do not enforce the exact size provided by this function, as the lower layer may and will send more or less data.
    pub inline fn suggestedRecvSize(self: NetworkDataProvider) usize {
        return self.vtable.suggestedRecvSizeFn(self.ptr);
    }

    /// Sets user data for the network provider.
    ///
    /// It will be provided as the second argument when the `SendCallbackFn` is called.
    pub inline fn setUserData(self: NetworkDataProvider, ptr: ?*anyopaque) void {
        return self.vtable.setUserDataFn(self.ptr, ptr);
    }

    /// Sets the send callback for the network provider.
    /// The callback will be called when the network provider wants to send data.
    ///
    /// If the upper layers sets the received data as null, the interface **must** not be used after the callback returns.
    pub inline fn setSendCallback(self: NetworkDataProvider, func: *const SendCallbackFn) void {
        return self.vtable.setSendCallbackFn(self.ptr, func);
    }

    /// Sends a particular event to the network provider.
    ///
    /// At least the `Connected` and `Disconnected` events should be implemented by the lower network layer.
    pub inline fn sendEvent(self: NetworkDataProvider, event: ConnectionEvent) void {
        return self.vtable.sendEventFn(self.ptr, event);
    }

    pub inline fn getConnectionDetails(self: NetworkDataProvider) ConnectionInfo {
        return self.vtable.getConnectionDetails(self.ptr);
    }

    pub inline fn setRecvEventCallback(self: NetworkDataProvider, func: *const RecvEventCallback) void {
        return self.vtable.setRecvEventCallback(self.ptr, func);
    }
};
