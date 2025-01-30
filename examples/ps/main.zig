const std = @import("std");
const Ollama = @import("ollama").Ollama;

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    var ollama = try Ollama.init(.{ .host = "localhost", .port = 11434, .allocator = allocator });
    defer ollama.deinit();

    var responses = try ollama.ps();
    while (try responses.next()) |response| {
        const content = response.models;
        for (content) |model| {
            const name = model.name;
            std.debug.print("running model: {s}\n", .{name});
        }
    }
}
