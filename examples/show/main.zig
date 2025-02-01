const std = @import("std");
const Ollama = @import("ollama").Ollama;

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    var ollama = try Ollama.init(.{ .host = "localhost", .port = 11434, .allocator = allocator });
    defer ollama.deinit();

    var responses = try ollama.show("llama3.2");
    while (try responses.next()) |response| {
        // std.debug.print("license: {s}\n", .{response.license});
        // std.debug.print("modelfile: {s}\n", .{response.modelfile});
        std.debug.print("details.family: {s}\n", .{response.details.family});
        std.debug.print("details.families: {s}\n", .{response.details.families.?});
        std.debug.print("details.parameter_size: {s}\n", .{response.details.parameter_size});
        std.debug.print("details.parent_model: {s}\n", .{response.details.parent_model});
        std.debug.print("details.quantization_level: {s}\n", .{response.details.quantization_level});
        // std.debug.print("modified_at: {s}\n", .{response.modified_at});
        // std.debug.print("parameters: {s}\n", .{response.parameters});
        // std.debug.print("template: {s}\n", .{response.template});
    }
}
