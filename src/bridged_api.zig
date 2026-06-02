const TestApi = @import("./lib/api/bridged/test.zig");

pub const Methods = .{
    .Client = .{
        .init = TestApi.init,
        .deinit = TestApi.deinit,
        .sendMessage = TestApi.sendMessage,
        .terminate = TestApi.terminate,
        .testReturnEnum = TestApi.testReturnEnum,
    },
};
