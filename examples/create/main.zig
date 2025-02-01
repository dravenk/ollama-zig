const std = @import("std");
const Ollama = @import("ollama").Ollama;

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    var ollama = try Ollama.init(.{ .host = "localhost", .port = 11434, .allocator = allocator });
    defer ollama.deinit();

    var responses = try ollama.create(.{ .model = "mario", .from = "llama3.2" });
    while (try responses.next()) |response| {
        std.debug.print("create model, status:{s}\n", .{response.status});
    }
}
