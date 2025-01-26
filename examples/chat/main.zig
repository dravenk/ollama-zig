const std = @import("std");
const Ollama = @import("ollama").Ollama;
const RequestOptions = @import("ollama").RequestOptions;
const OllamaResponse = @import("ollama").OllamaResponse;

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    var ollama = try Ollama.init(.{ .host = "localhost", .port = 11434, .allocator = allocator });

    const message = [_]RequestOptions.chat.Message{
        .{ .role = "user", .content = "Why is the sky blue?" },
    };

    var req = try ollama.chat(.{ .model = "llama3.2", .messages = &message });
    defer req.deinit();

    const responses: []OllamaResponse = try ollama.full_response(&req);
    for (responses) |response| {
        const json = try response.to_json(allocator);
        std.debug.print("{s}\n", .{json});
    }
}
