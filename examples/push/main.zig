const std = @import("std");
const Ollama = @import("ollama").Ollama;

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    var ollama = try Ollama.init(.{ .host = "localhost", .port = 11434, .allocator = allocator });
    defer ollama.deinit();

    var responses = try ollama.push(.{ .model = "dravenk/llama3.2", .stream = false });
    while (try responses.next()) |response| {
        const status = response.status;
        std.debug.print("pushed model, status:{s}\n", .{status});
    }
}
