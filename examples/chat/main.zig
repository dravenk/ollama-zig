const std = @import("std");
const Ollama = @import("ollama").Ollama;

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    var ollama = try Ollama.init(.{ .host = "localhost", .port = 11434, .allocator = allocator });
    defer ollama.deinit();

    var responses = try ollama.chat(.{ .model = "llama3.2", .messages = &.{
        .{ .role = .user, .content = "Why is the sky blue?" },
    } });
    while (try responses.next()) |response| {
        const content = response.message.content;
        std.debug.print("{s}", .{content});
    }
}
