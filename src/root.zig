const std = @import("std");
const tl_tests = @import("lib/tl/api_tests.zig");
const tl = @import("tl");
const generate = @import("./lib/proto/auth_key.zig");
const Transport = @import("./lib/transport.zig").Transport;
const utils = @import("./lib/proto/utils.zig");
const CompileOptions = @import("mzproto_options");
const AuthKey = @import("./lib/proto/auth_key.zig");
const ClientManager = @import("./lib/client_manager.zig");
const Client = @import("./lib/client.zig");
const Session = @import("./lib/proto/session.zig");
const SessionPool = @import("./lib/proto/session_pool.zig");

const Storage = @import("./lib/storage.zig");

const TransportConnector = @import("./lib/transport_connector.zig");

const public_api = @import("mzproto");

test {
    _ = Client;
    _ = Client.init;
    _ = Client.backgroundInit;
    _ = tl_tests;
    _ = Storage;
    _ = AuthKey;
    _ = Session;
    _ = AuthKey.generate;
    _ = @import("./lib/crypto/miller_rabin.zig");
    _ = tl;
    _ = @import("./lib/tl/api_tests.zig");
    _ = @import("./lib/transport/dummy.zig");
    _ = @import("./lib/proto/session_test_server.zig");
    _ = @import("./lib/crypto/mt1.zig");
    _ = @import("./lib/crypto/mt2.zig");
}
