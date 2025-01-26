const std = @import("std");

pub const RequestOptions = struct {
    const Self = @This();

    const Format = enum {
        json,
        markdown,
        html,
        text,
    };

    pub const chat = struct {
        model: []const u8,
        // messages: []const Message,
        tools: ?[]const Tool = null,
        format: ?Format = null,
        // options: ?Options = null,
        stream: bool = true,
        keep_alive: ?u64 = null,

        messages: []const Message = undefined,

        pub const Message = struct {
            role: []const u8,
            content: []const u8,
            images: ?[]const u8 = undefined,
        };

        const Tool = struct {
            // Define tool fields here
        };

        // const Format = enum {
        //     json,
        //     markdown,
        //     html,
        //     text,
        // };
    };
};
