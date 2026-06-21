const TestApi = @import("./lib/api/bridged/test.zig");
const Updates = @import("./lib/api/bridged/updates.zig");
const Authentication = @import("./lib/api/bridged/auth.zig");
const Root = @import("root.zig");
pub const Methods = .{
    .Client = .{
        .init = TestApi.init,
        .deinit = TestApi.deinit,
        .isTerminated = TestApi.isTerminated,
        .sendMessage = TestApi.sendMessage,
        .terminate = TestApi.terminate,
        .testReturnEnum = TestApi.testReturnEnum,
        .nextUpdate = Updates.nextUpdate,
        .authenticateBot = Authentication.authenticateBot,
    },
};

test {
    _ = Root;
}