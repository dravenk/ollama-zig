const std = @import("std");

pub const Ollama = struct {
    const Self = @This();

    allocator: std.mem.Allocator,

    host: []const u8 = "",

    pub fn init(self: Self) !Ollama {
        return .{ .allocator = self.allocator };
    }

    const chatOptions = struct {
        model: []const u8,
        const message = struct {
            role: []const u8,
            content: []const u8,
        };
        const messages: []const message = undefined;
    };
    // model='llama3.2', messages=[{'role': 'user', 'content': 'Why is the sky blue?'}]
    pub fn chat(self: *Self, options: chatOptions) !std.http.Client.Response {
        const chat_message = options.messages[0];
        const ollama_role = chat_message.role;
        const ollama_content = chat_message.content;
        _ = ollama_role;
        _ = ollama_content;
        _ = self;
    }

    fn create_request(self: *Self) ![]const u8 {
        // Create an HTTP client.
        var client = std.http.Client{ .allocator = self.allocator };
        defer client.deinit();

        const url = try std.fmt.allocPrint(self.allocator, "http://127.0.0.1:{any}/test", .{8080});
        defer self.allocator.free(url);
        var req = try fetch(&client, .{ .method = .GET, .location = .{ .url = url } });
        defer req.deinit();

        const body_buffer = req.reader().readAllAlloc(self.allocator, req.response.content_length.?) catch unreachable;
        return body_buffer;
    }

    pub fn raw_request(self: *Self) ![]const u8 {
        const body_buffer = try self.create_request();
        return body_buffer;
    }
};

/// see  std.http.Client.fetch
fn fetch(client: *std.http.Client, options: std.http.Client.FetchOptions) !std.http.Client.Request {
    const uri = switch (options.location) {
        .url => |u| try std.Uri.parse(u),
        .uri => |u| u,
    };
    // var server_header_buffer = options.server_header_buffer orelse (16 * 1024);
    var server_header_buffer: [1024]u8 = undefined;

    const method: std.http.Method = options.method orelse
        if (options.payload != null) .POST else .GET;

    var req = try std.http.Client.open(client, method, uri, .{
        .server_header_buffer = options.server_header_buffer orelse &server_header_buffer,
        .redirect_behavior = options.redirect_behavior orelse
            if (options.payload == null) @enumFromInt(3) else .unhandled,
        .headers = options.headers,
        .extra_headers = options.extra_headers,
        .privileged_headers = options.privileged_headers,
        // .keep_alive = options.keep_alive,
        .keep_alive = false,
    });

    if (options.payload) |payload| req.transfer_encoding = .{ .content_length = payload.len };

    try req.send();

    if (options.payload) |payload| try req.writeAll(payload);

    try req.finish();
    try req.wait();
    return req;
}
