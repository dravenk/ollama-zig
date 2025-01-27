const std = @import("std");
const Ollama = @import("ollama").Ollama;

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    var ollama = try Ollama.init(.{ .host = "localhost", .port = 11434, .allocator = allocator });
    defer ollama.deinit();

    var req = try ollama.chat(.{ .model = "llama3.2", .messages = &.{
        .{ .role = .user, .content = "Why is the sky blue?" },
    } });
    defer req.deinit();

    // not streaming responses
    const responses = try ollama.full_response(&req);
    for (responses) |response| {
        const json = try response.to_json(allocator);
        std.debug.print("{s}\n", .{json});
    }
}
