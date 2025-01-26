const std = @import("std");
const Ollama = @import("ollama").Ollama;
const RequestOptions = @import("ollama").RequestOptions;

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    var ollama = try Ollama.init(.{ .host = "localhost", .port = 11434, .allocator = allocator });

    const message = [_]RequestOptions.chat.Message{
        .{ .role = "user", .content = "Why is the sky blue?" },
    };

    var req = try ollama.chat(.{ .model = "llama3.2", .messages = &message });
    defer req.deinit();

    const response = try ollama.full_response(&req);
    std.debug.print("response:\r\n {s}\n", .{response});
}
