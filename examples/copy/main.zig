const std = @import("std");
const Ollama = @import("ollama").Ollama;

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    var ollama = try Ollama.init(.{ .host = "localhost", .port = 11434, .allocator = allocator });
    defer ollama.deinit();

    const status: std.http.Status = try ollama.copy("llama3.2", "user/llama3.2");
    if (status == std.http.Status.ok) {
        std.debug.print("copied model, status:{any}\n", .{status});
    } else {
        std.debug.print("failed to copy model, status:{any}\n", .{status});
    }
}
