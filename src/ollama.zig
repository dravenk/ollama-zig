const std = @import("std");

pub const types = @import("types.zig");
pub const Apis = @import("apis.zig").Apis;

fn readUntilDelimiter(allocator: std.mem.Allocator, reader: *std.io.AnyReader, delimiter: u8) !?[]u8 {
    var buffer = std.ArrayList(u8).init(allocator);
    defer allocator.free(buffer.items);
    while (true) {
        const byte = reader.readByte() catch break;
        if (byte == 0 or byte == delimiter) break;
        try buffer.append(byte);
    }
    return try buffer.toOwnedSlice();
}

fn ResponseStream(comptime T: type) type {
    return struct {
        request: *std.http.Client.Request,
        var done: bool = false;

        pub fn next(self: @This()) !?T {
            const allocator = self.request.client.allocator;
            if (done) {
                self.request.deinit();
                return null;
            }

            var reader = self.request.reader();

            var buffer = std.ArrayList(u8).init(allocator);
            defer allocator.free(buffer.items);

            reader.streamUntilDelimiter(buffer.writer(), '\n', null) catch |err| {
                switch (err) {
                    // error.EndOfStream => return null,
                    error.EndOfStream => {
                        done = true;
                        //TODO if streamable return null;
                    },
                    else => return err,
                }
            };

            if (buffer.items.len == 0) {
                done = true;
                return null;
            }
            const response = try buffer.toOwnedSlice();

            const parsed = std.json.parseFromSlice(T, allocator, response, .{
                .ignore_unknown_fields = true,
            }) catch |err| {
                std.debug.print("error parsing response: {s} | err {any}\n", .{ response, err });
                done = true;
                self.request.deinit();
                return null;
            };

            // defer parsed.deinit(); // TODO
            // check if T have a field done
            if (@hasField(T, "done")) {
                done = parsed.value.done;
            }

            // check if T have a field status
            if (@hasField(T, "status")) {
                // T.status == "success"
                if (std.mem.eql(u8, parsed.value.status, "success")) {
                    done = true;
                }
            }

            return parsed.value;
        }
    };
}

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

    pub fn wait(self: *Self, req: *std.http.Client.Request, comptime T: type) ![]T {
        var reader = req.reader();
        var buffer = std.ArrayList(u8).init(self.allocator);
        defer self.allocator.free(buffer.items);

        var responses = std.ArrayList(T).init(self.allocator);
        defer responses.deinit();

        while (true) {
            const byte = reader.readByte() catch break;
            if (byte == 0) break;
            try buffer.append(byte);

            // If we see a newline, we have a full response.
            if (byte == '\n') {
                const response_slice = try buffer.toOwnedSlice();
                const response_object = try std.json.parseFromSlice(T, self.allocator, response_slice, .{ .ignore_unknown_fields = true });
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
    pub fn chat(self: *Self, opts: types.Request.chat) !ResponseStream(types.Response.chat) {
        var req = try self.create_request(Apis.chat, opts);
        return .{ .request = &req };
    }

    pub fn generate(self: *Self, opts: types.Request.generate) !ResponseStream(types.Response.generate) {
        var req = try self.create_request(Apis.generate, opts);
        return .{ .request = &req };
    }

    pub fn ps(self: *Self) !ResponseStream(types.Response.ps) {
        var req = try self.noBodyRequest(Apis.ps);
        return .{ .request = &req };
    }

    pub fn tags(self: *Self) !ResponseStream(types.Response.tags) {
        var req = try self.noBodyRequest(Apis.tags);
        return .{ .request = &req };
    }

    pub fn show(self: *Self, model: []const u8) !ResponseStream(types.Response.show) {
        const opts: types.Request.show = .{ .model = model };
        var req = try self.create_request(Apis.show, opts);
        return .{ .request = &req };
    }

    pub fn push(self: *Self, opts: types.Request.push) !ResponseStream(types.Response.push) {
        var req = try self.create_request(Apis.push, opts);
        return .{ .request = &req };
    }

    pub fn pull(self: *Self, opts: types.Request.pull) !ResponseStream(types.Response.pull) {
        var req = try self.create_request(Apis.pull, opts);
        return .{ .request = &req };
    }

    pub fn copy(self: *Self, source: []const u8, destination: []const u8) !std.http.Status {
        const opts: types.Request.copy = .{
            .source = source,
            .destination = destination,
        };
        const req = try self.create_request(Apis.copy, opts);
        return req.response.status;
    }

    fn noBodyRequest(self: *Self, api_type: Apis) !std.http.Client.Request {
        var client = std.http.Client{ .allocator = self.allocator };

        const api_str = api_type.path();
        const method = api_type.method();
        const url = try std.fmt.allocPrint(self.allocator, "{s}://{s}:{any}{s}", .{ self.schema, self.host, self.port, api_str });
        defer self.allocator.free(url);

        return try fetch(&client, .{
            .method = method,
            .keep_alive = false,
            .location = .{ .url = url },
        });
    }

    fn create_request(self: *Self, api_type: Apis, values: anytype) !std.http.Client.Request {
        // Create an HTTP client.
        var client = std.http.Client{ .allocator = self.allocator };
        // defer client.deinit();

        const api_str = api_type.path();
        const method = api_type.method();
        const url = try std.fmt.allocPrint(self.allocator, "{s}://{s}:{any}{s}", .{ self.schema, self.host, self.port, api_str });
        defer self.allocator.free(url);

        return try self.json_request(&client, method, url, values);
    }

    fn json_request(self: *Self, client: *std.http.Client, method: std.http.Method, url: []const u8, values: anytype) !std.http.Client.Request {
        var out = std.ArrayList(u8).init(self.allocator);
        defer out.deinit();

        try std.json.stringify(values, .{
            .emit_null_optional_fields = false,
        }, out.writer());

        const slice = try out.toOwnedSlice();

        return try fetch(client, .{
            .method = method,
            .keep_alive = false,
            .location = .{ .url = url },
            .payload = slice,
        });
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

    var req = try client.open(method, uri, .{
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
