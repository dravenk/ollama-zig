const std = @import("std");
const Ollama = @import("../src/ollama.zig").Ollama;

pub fn mian() !void {
    const ollama = try Ollama.init(.{ .allocator = std.heap.page_allocator });
    const message = &[_]Ollama.chatOptions.message{
        .{ .role = "user", .content = "Why is the sky blue?" },
    };
    const response = try ollama.chat(.{ .model = "llama3.2", .messages = message });
    _ = response;
}
