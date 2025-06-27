const std = @import("std");

pub const types = @import("types.zig");
pub const Api = @import("api.zig").Api;

fn ResponseStream(comptime T: type) type {
    return struct {
        request: *std.http.Client.Request,
        var done: bool = false;

        pub fn deinit(self: @This()) void {
            self.request.client.allocator.destroy(self.request);
        }

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

            if (self.request.response.status.class() != .success) {
                std.debug.print("Response: {s}\n", .{response});
                done = true;

                const parsed = try std.json.parseFromSlice(T.@"error", allocator, response, .{
                    .ignore_unknown_fields = true,
                });
                std.debug.print("Error: {s}", .{parsed.value.@"error"});

                return null;
            }

            const parsed = std.json.parseFromSlice(T, allocator, response, .{
                .ignore_unknown_fields = true,
            }) catch |err| {
                std.debug.print("Parsing response: {s} | err {any}\n", .{ response, err });
                done = true;
                self.request.deinit();
                return null;
            };

            // check if T have a field done
            if (@hasField(T, "done")) {
                done = parsed.value.done;
            }

            // check if T have a field status
            if (@hasField(T, "status")) {
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

    // model='llama3.2', messages=[{'role': 'user', 'content': 'Why is the sky blue?'}]
    pub fn chat(self: *Self, opts: types.Request.chat) !ResponseStream(types.Response.chat) {
        const req = try self.createRequest(Api.chat, opts);
        return .{ .request = req };
    }

    pub fn generate(self: *Self, opts: types.Request.generate) !ResponseStream(types.Response.generate) {
        const req = try self.createRequest(Api.generate, opts);
        return .{ .request = req };
    }

    pub fn ps(self: *Self) !ResponseStream(types.Response.ps) {
        const req = try self.noBodyRequest(Api.ps);
        return .{ .request = req };
    }

    pub fn embed(self: *Self, opts: types.Request.embed) !ResponseStream(types.Response.embed) {
        const req = try self.createRequest(Api.embed, opts);
        return .{ .request = req };
    }

    pub fn version(self: *Self) !ResponseStream(types.Response.version) {
        const req = try self.noBodyRequest(Api.version);
        return .{ .request = req };
    }

    pub fn tags(self: *Self) !ResponseStream(types.Response.tags) {
        const req = try self.noBodyRequest(Api.tags);
        return .{ .request = req };
    }

    pub fn show(self: *Self, model: []const u8) !ResponseStream(types.Response.show) {
        const opts: types.Request.show = .{ .model = model };
        const req = try self.createRequest(Api.show, opts);
        return .{ .request = req };
    }

    pub fn create(self: *Self, opts: types.Request.create) !ResponseStream(types.Response.create) {
        const req = try self.createRequest(Api.show, opts);
        return .{ .request = req };
    }

    pub fn push(self: *Self, opts: types.Request.push) !ResponseStream(types.Response.push) {
        const req = try self.createRequest(Api.push, opts);
        return .{ .request = req };
    }

    pub fn pull(self: *Self, opts: types.Request.pull) !ResponseStream(types.Response.pull) {
        const req = try self.createRequest(Api.pull, opts);
        return .{ .request = req };
    }

    pub fn copy(self: *Self, source: []const u8, destination: []const u8) !std.http.Status {
        const opts: types.Request.copy = .{
            .source = source,
            .destination = destination,
        };
        const req = try self.createRequest(Api.copy, opts);
        defer self.allocator.destroy(req);
        return req.response.status;
    }

    fn noBodyRequest(self: *Self, api_type: Api) !*std.http.Client.Request {
        const client = try self.allocator.create(std.http.Client);
        errdefer self.allocator.destroy(client);
        client.* = std.http.Client{ .allocator = self.allocator };

        const api_str = api_type.path();
        const method = api_type.method();
        const url = try std.fmt.allocPrint(self.allocator, "{s}://{s}:{any}{s}", .{ self.schema, self.host, self.port, api_str });
        defer self.allocator.free(url);

        return try fetch(client, .{
            .method = method,
            .keep_alive = false,
            .location = .{ .url = url },
        });
    }

    fn createRequest(self: *Self, api_type: Api, values: anytype) !*std.http.Client.Request {
        const client = try self.allocator.create(std.http.Client);
        errdefer self.allocator.destroy(client);
        client.* = std.http.Client{ .allocator = self.allocator };
        // defer client.deinit();

        const api_str = api_type.path();
        const method = api_type.method();
        const url = try std.fmt.allocPrint(self.allocator, "{s}://{s}:{any}{s}", .{ self.schema, self.host, self.port, api_str });
        defer self.allocator.free(url);

        return try self.json_request(client, method, url, values);
    }

    fn json_request(self: *Self, client: *std.http.Client, method: std.http.Method, url: []const u8, values: anytype) !*std.http.Client.Request {
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

//
fn fetch(client: *std.http.Client, options: std.http.Client.FetchOptions) !*std.http.Client.Request {
    const uri = switch (options.location) {
        .url => |u| try std.Uri.parse(u),
        .uri => |u| u,
    };

    const server_header_buffer = try client.allocator.alloc(u8, 1024);
    defer client.allocator.free(server_header_buffer);

    const method: std.http.Method = options.method orelse
        if (options.payload != null) .POST else .GET;

    const req = try client.allocator.create(std.http.Client.Request);
    errdefer client.allocator.destroy(req);

    req.* = try client.open(method, uri, .{
        .server_header_buffer = options.server_header_buffer orelse server_header_buffer,
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
