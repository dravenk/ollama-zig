const std = @import("std");
// const Ollama = @import("ollama.zig").Ollama;
const Options = @import("request_options.zig");

const Chat = @This();

// const ChatParameters = struct {
//     model: []const u8,
//     messages: []const Message,
//     tools: ?[]const Tool = null,
//     format: ?Format = null,
//     options: ?Options = null,
//     stream: bool = true,
//     keep_alive: ?u64 = null,
// };

// const Message = struct {
//     role: []const u8,
//     content: []const u8,
//     images: ?[]const u8 = null,
//     tool_calls: ?[]const ToolCall = null,
// };

const Tool = struct {
    // Define tool fields here
};

const Format = enum {
    json,
    markdown,
    html,
    text,
};

// const Options: anyframe = struct {
//     // Define options fields here
// };

const ToolCall = struct {
    // Define tool call fields here
};

// model='llama3.2', messages=[{'role': 'user', 'content': 'Why is the sky blue?'}]
pub fn chat(options: Options.RequestOptions.chat) !std.http.Client.Response {
    const chat_message = options.messages[0];
    const ollama_role = chat_message.role;
    const ollama_content = chat_message.content;
    _ = ollama_role;
    _ = ollama_content;
    // _ = self;
}
