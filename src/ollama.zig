const std = @import("std");

pub const types = @import("types.zig");

pub const ChatResponse = struct {
    // Required fields
    model: []const u8 = "",
    created_at: []const u8 = "",
    message: ChatResponseMessage = undefined,
    done: bool = false,

    // Optional fields
    done_reason: ?[]const u8 = null,
    total_duration: ?u64 = null,
    load_duration: ?u64 = null,
    prompt_eval_count: ?u32 = null,
    prompt_eval_duration: ?u64 = null,
    eval_count: ?u32 = null,
    eval_duration: ?u64 = null,

    pub fn to_json(self: ChatResponse, allocator: std.mem.Allocator) ![]const u8 {
        var out = std.ArrayList(u8).init(allocator);
        defer out.deinit();
        try std.json.stringify(self, .{
            .emit_null_optional_fields = false,
        }, out.writer());
        return try out.toOwnedSlice();
    }
};

pub const ChatResponseMessage = struct {
    role: []const u8,
    content: []const u8,
};

pub const Ollama = struct {
    const Self = @This();

    allocator: std.mem.Allocator,

    schema: []const u8 = "http",

    host: []const u8 = "localhost",
    port: u16 = 11434,

    pub fn init(self: Self) !Ollama {
        return .{ .allocator = self.allocator };
    }
    pub fn deinit(self: *Self) void {
        self.allocator = undefined;
    }

    pub fn full_response(self: *Self, req: *std.http.Client.Request) ![]ChatResponse {
        var reader = req.reader();
        var buffer = std.ArrayList(u8).init(self.allocator);
        defer self.allocator.free(buffer.items);

        var responses = std.ArrayList(ChatResponse).init(self.allocator);
        defer responses.deinit();

        while (true) {
            const byte = reader.readByte() catch break;
            if (byte == 0) break;
            try buffer.append(byte);

            // If we see a newline, we have a full response.
            if (byte == '\n') {
                const response_slice = try buffer.toOwnedSlice();
                const response_object = try std.json.parseFromSlice(ChatResponse, self.allocator, response_slice, .{ .ignore_unknown_fields = true });
                const ollama_response = response_object.value;
                try responses.append(ollama_response);
                buffer.clearRetainingCapacity();
                if (ollama_response.done) break;
            }
        }
        return try responses.toOwnedSlice();
    }

    // model='llama3.2', messages=[{'role': 'user', 'content': 'Why is the sky blue?'}]
    // pub fn chat(self: *Self, opts: types.Request.chat) !std.http.Client.Response {
    pub fn chat(self: *Self, opts: types.Request.chat) !std.http.Client.Request {
        return try self.create_request(opts);
    }

    fn create_request(self: *Self, chat_options: types.Request.chat) !std.http.Client.Request {
        // Create an HTTP client.
        var client = std.http.Client{ .allocator = self.allocator };
        // defer client.deinit();

        const api_str = "api/chat";
        const url = try std.fmt.allocPrint(self.allocator, "{s}://{s}:{any}/{s}", .{ self.schema, self.host, self.port, api_str });
        defer self.allocator.free(url);
        return try self.json_request(&client, url, chat_options);
    }

    fn json_request(self: *Self, client: *std.http.Client, url: []const u8, chat_options: types.Request.chat) !std.http.Client.Request {
        var out = std.ArrayList(u8).init(self.allocator);
        defer out.deinit();

        try std.json.stringify(chat_options, .{
            .emit_null_optional_fields = false,
        }, out.writer());

        const slice = try out.toOwnedSlice();

        return try fetch(client, .{ .method = .POST, .keep_alive = false, .location = .{ .url = url }, .payload = slice });
    }
};

/// see  std.http.Client.fetch
fn fetch(client: *std.http.Client, options: std.http.Client.FetchOptions) !std.http.Client.Request {
    const uri = switch (options.location) {
        .url => |u| try std.Uri.parse(u),
        .uri => |u| u,
    };
    // var server_header_buffer: []u8 = options.server_header_buffer;
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
        .keep_alive = options.keep_alive,
    });

    if (options.payload) |payload| req.transfer_encoding = .{ .content_length = payload.len };
    try req.send();

    if (options.payload) |payload| try req.writeAll(payload);

    try req.finish();
    try req.wait();
    return req;
}
