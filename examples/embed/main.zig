const std = @import("std");
const Ollama = @import("ollama").Ollama;

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    var ollama = try Ollama.init(.{ .host = "localhost", .port = 11434, .allocator = allocator });
    defer ollama.deinit();

    var input = std.ArrayList([]const u8).init(allocator);
    try input.append("The sky is blue because of rayleigh scattering");
    try input.append("Grass is green because of chlorophyll");

    var responses = try ollama.embed(.{
        .model = "dravenk/llama3.2",
        .input = try input.toOwnedSlice(),
    });
    while (try responses.next()) |response| {
        std.debug.print("total_duration: {d}\n", .{response.total_duration.?});
        std.debug.print("prompt_eval_count: {d}\n", .{response.prompt_eval_count.?});
    }
}
