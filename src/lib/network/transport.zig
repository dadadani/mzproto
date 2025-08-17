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

//! Transport interfaces used to compose network layers via vtables.
//! 
//! - TransportReader: upstream-facing sink for bytes arriving from lower layers.
//! - TransportWriter: downstream-facing source that sends bytes to lower layers.
//! - TransportControl: wiring/lifecycle hook used to connect reader/writer pairs and deinit.
//! 
//! A transport "layer" typically exposes its own Reader/Writer and accepts a lower layer
//! Reader/Writer via TransportControl.setReader/setWriter to form a chain.

const std = @import("std");

const transport = @This();

pub const Error = error{ ConnectionClosed, WriterRequired } || std.mem.Allocator.Error;

pub const Control = union(enum) {
    Connect: struct {},
    Disconnect: struct {},
    ConnectError: struct {},
};

/// Connection metadata used by lower-level transports (e.g. TCP dial target).
pub const ConnectionInfo = struct {
    dcId: u8,
    testMode: bool,
    media: bool,
    address: std.net.Address,
};

/// Upstream-facing reader: receives bytes from a lower level.
/// Lifetime: data slices passed to `send` are only valid for the duration of the call.
pub const TransportReader = struct {
    vtable: struct {
        ctx: *anyopaque,
        control: *const fn (self: *anyopaque, ctrl: Control) void,
        send: *const fn (self: *anyopaque, data: []const u8) void,
        /// Hint to lower layer for optimal next read size.
        sendSuggested: *const fn (self: *anyopaque) usize,
        /// Provide connection info to lower layers (e.g. for dialing).
        connectionInfo: *const fn (self: *anyopaque) ConnectionInfo,
    },

    pub inline fn control(self: TransportReader, ctrl: Control) void {
        self.vtable.control(self.vtable.ctx, ctrl);
    }

    /// Receive a chunk of data. The slice is ephemeral.
    pub inline fn send(self: TransportReader, data: []const u8) void {
        self.vtable.send(self.vtable.ctx, data);
    }

    /// Suggested next chunk size (optional hint).
    pub inline fn sendSuggested(self: TransportReader) usize {
        return self.vtable.sendSuggested(self.vtable.ctx);
    }

    /// Get connection parameters for lower layers.
    pub inline fn connectionInfo(self: TransportReader) ConnectionInfo {
        return self.vtable.connectionInfo(self.vtable.ctx);
    }
};

/// Downstream-facing writer: sends bytes to a lower level.
/// Lifetime: data slices passed to `send` are only valid for the duration of the call.
pub const TransportWriter = struct {
    vtable: struct {
        ctx: *anyopaque,
        control: *const fn (self: *anyopaque, ctrl: Control) void,
        send: *const fn (self: *anyopaque, data: []const u8) Error!void,
    },

    /// Send a chunk of data downstream.
    /// Returns ConnectionClosed if the link is unavailable.
    pub inline fn send(self: TransportWriter, data: []const u8) Error!void {
        return self.vtable.send(self.vtable.ctx, data);
    }

    /// Deliver a control message downstream.
    pub inline fn control(self: TransportWriter, ctrl: Control) void {
        self.vtable.control(self.vtable.ctx, ctrl);
    }
};

/// Control surface to wire a transport layer into a chain and to deinitialize it.
pub const TransportControl = struct {
    vtable: struct {
        ctx: *anyopaque,
        /// Provide the lower-level writer to this layer.
        setWriter: *const fn (self: *anyopaque, writer: TransportWriter) void,
        /// Provide the lower-level reader to this layer.
        setReader: *const fn (self: *anyopaque, reader: TransportReader) void,
        /// Tear down the layer. When teardown completes, invoke cb(ctx).
        deinit: *const fn (self: *anyopaque, ctx: ?*anyopaque, cb: *const (fn (self: ?*anyopaque) void)) void,
    },

    pub inline fn setWriter(self: TransportControl, writer: TransportWriter) void {
        return self.vtable.setWriter(self.vtable.ctx, writer);
    }

    pub inline fn setReader(self: TransportControl, reader: TransportReader) void {
        return self.vtable.setReader(self.vtable.ctx, reader);
    }

    /// Begin asynchronous teardown; invoke cb(ctx) when fully deinitialized.
    pub inline fn deinit(self: TransportControl, ctx: ?*anyopaque, cb: (fn (self: ?*anyopaque) void)) void {
        return self.vtable.deinit(self.vtable.ctx, ctx, cb);
    }
};

/// Bundle of reader/writer/control constituting a transport layer instance.
pub const TransportReturn = struct {
    reader: TransportReader,
    writer: TransportWriter,
    control: TransportControl,
};

/// Factory for producing a transport layer instance.
pub const TransportInitializer = struct {
    vtable: struct {
        ctx: *anyopaque,
        init: (*const fn (self: *anyopaque) transport.Error!TransportReturn),
    },

    /// Construct the transport layer instance.
    pub inline fn init(self: TransportInitializer) transport.Error!TransportReturn {
        return self.vtable.init(self.vtable.ctx);
    }
};

