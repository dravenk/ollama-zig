const std = @import("std");
const json = std.json;
const base64 = std.base64;
const time = std.time;
const fs = std.fs;

pub const RequestError = error{
    InvalidRequest,
    InvalidResponse,
    InvalidImageData,
    FileNotFound,
    Base64DecodingFailed,
};

pub const ResponseError = struct {
    error_msg: []const u8,
    status_code: i32,

    pub fn init(error_msg: []const u8, status_code: i32) ResponseError {
        return .{
            .error_msg = error_msg,
            .status_code = status_code,
        };
    }
};

pub const Format = enum {
    json,
    markdown,
    html,
    text,
};

pub const Image = struct {
    value: union(enum) {
        path: []const u8,
        bytes: []const u8,
        base64: []const u8,
    },

    pub fn fromPath(path: []const u8) !Image {
        const file = try std.fs.openFileAbsolute(path, .{});
        defer file.close();

        const contents = try file.readToEndAlloc(std.heap.page_allocator, std.math.maxInt(usize));
        defer std.heap.page_allocator.free(contents);

        var encoded: [base64.Base64Encoder.calcSize(contents.len)]u8 = undefined;
        _ = base64.standard.Encoder.encode(&encoded, contents);

        return Image{ .value = .{ .base64 = try std.heap.page_allocator.dupe(u8, &encoded) } };
    }
};

pub const Options = struct {
    // Load time options
    numa: ?bool = null,
    num_ctx: ?u32 = null,
    num_batch: ?u32 = null,
    num_gpu: ?u32 = null,
    main_gpu: ?u32 = null,
    low_vram: ?bool = null,
    f16_kv: ?bool = null,
    logits_all: ?bool = null,
    vocab_only: ?bool = null,
    use_mmap: ?bool = null,
    use_mlock: ?bool = null,
    embedding_only: ?bool = null,
    num_thread: ?u32 = null,

    // Runtime options
    num_keep: ?u32 = null,
    seed: ?u32 = null,
    num_predict: ?u32 = null,
    top_k: ?u32 = null,
    top_p: ?f32 = null,
    tfs_z: ?f32 = null,
    typical_p: ?f32 = null,
    repeat_last_n: ?u32 = null,
    temperature: ?f32 = null,
    repeat_penalty: ?f32 = null,
    presence_penalty: ?f32 = null,
    frequency_penalty: ?f32 = null,
    mirostat: ?u32 = null,
    mirostat_tau: ?f32 = null,
    mirostat_eta: ?f32 = null,
    penalize_newline: ?bool = null,
    stop: ?[]const []const u8 = null,
};

pub const Role = enum {
    user,
    assistant,
    system,
    tool,
};

pub const Message = struct {
    role: Role,
    content: []const u8,
    images: ?[]Image = null,
    // tool_calls: ?[]ToolCall = null,
    // pub const ToolCall = struct {
    //     function: Function,

    //     pub const Function = struct {
    //         name: []const u8,
    //         arguments: std.StringHashMap(json.Value),
    //     };
    // };
};

pub const Tool = struct {};

// pub const Tool = struct {
//     type: []const u8 = "function",
//     function: ?Function = null,

//     pub const Function = struct {
//         name: ?[]const u8 = null,
//         description: ?[]const u8 = null,
//         parameters: ?Parameters = null,

//         pub const Parameters = struct {
//             type: []const u8 = "object",
//             required: ?[][]const u8 = null,
//             properties: ?std.StringHashMap(Property) = null,

//             pub const Property = struct {
//                 type: ?[]const u8 = null,
//                 description: ?[]const u8 = null,
//             };
//         };
//     };
// };

pub const Request = struct {
    pub const generate = struct {
        model: []const u8,
        stream: bool = true,

        options: ?Options = null,
        format: ?[]const u8 = null,
        keep_alive: ?f32 = null,
        prompt: ?[]const u8 = null,
        suffix: ?[]const u8 = null,
        system: ?[]const u8 = null,
        template: ?[]const u8 = null,
        context: ?[]u32 = null,
        raw: ?bool = null,
        images: ?[]Image = null,
    };

    pub const chat = struct {
        model: []const u8,
        tools: ?[]const Tool = null,
        format: ?Format = null,
        stream: bool = true,
        keep_alive: ?u64 = null,
        messages: []const Message = undefined,
    };

    pub const embed = struct {
        model: []const u8,
        input: []const u8,
        truncate: ?bool = null,
        options: ?Options = null,
        keep_alive: ?f32 = null,
    };

    pub const create = struct {
        model: []const u8,
        stream: ?bool = null,
        quantize: ?[]const u8 = null,
        from: ?[]const u8 = null,
        files: ?std.StringHashMap([]const u8) = null,
        adapters: ?std.StringHashMap([]const u8) = null,
        template: ?[]const u8 = null,
        license: ?[]const u8 = null,
        system: ?[]const u8 = null,
        parameters: ?Options = null,
        messages: []const Message = undefined,
    };

    pub const delete = struct {
        model: []const u8,
    };

    pub const copy = struct {
        source: []const u8,
        destination: []const u8,
    };

    pub const pull = struct {
        model: []const u8,
        stream: ?bool = null,
        insecure: ?bool = null,
    };

    pub const push = struct {
        model: []const u8,
        stream: ?bool = null,
        insecure: ?bool = null,
    };
};

pub const Response = struct {
    pub const generate = struct {
        model: []const u8 = "",
        created_at: []const u8 = "",
        done: bool = false,
        response: []const u8,

        done_reason: ?[]const u8 = null,
        total_duration: ?u64 = null,
        load_duration: ?u64 = null,
        prompt_eval_count: ?u32 = null,
        prompt_eval_duration: ?u64 = null,
        eval_count: ?u32 = null,
        eval_duration: ?u64 = null,
        context: ?[]u32 = null,
    };

    pub const chat = struct {
        model: []const u8 = "",
        created_at: []const u8 = "",
        message: Message,
        done: bool = false,
        done_reason: ?[]const u8 = null,
        total_duration: ?u64 = null,
        load_duration: ?u64 = null,
        prompt_eval_count: ?u32 = null,
        prompt_eval_duration: ?u64 = null,
        eval_count: ?u32 = null,
        eval_duration: ?u64 = null,

        pub fn to_json(self: @This(), allocator: std.mem.Allocator) ![]const u8 {
            var out = std.ArrayList(u8).init(allocator);
            defer out.deinit();
            try std.json.stringify(self, .{
                .emit_null_optional_fields = false,
            }, out.writer());
            return try out.toOwnedSlice();
        }
    };

    pub const embed = struct {
        model: ?[]const u8 = null,
        created_at: ?[]const u8 = null,
        done: ?bool = null,
        done_reason: ?[]const u8 = null,
        total_duration: ?u64 = null,
        load_duration: ?u64 = null,
        prompt_eval_count: ?u32 = null,
        prompt_eval_duration: ?u64 = null,
        eval_count: ?u32 = null,
        eval_duration: ?u64 = null,
        embeddings: [][]f32,
    };

    pub const list = struct {
        pub const Model = struct {
            name: []const u8,
            model: []const u8,
            size: u64,
            digest: []const u8,
            details: ModelDetails,
            expires_at: ?[]const u8 = null,
            size_vram: ?u64 = null,
        };

        models: []Model,
    };

    pub const tags = struct {
        pub const Model = struct {
            name: []const u8,
            model: []const u8,
            size: u64,
            digest: []const u8,
            details: ModelDetails,
            expires_at: ?[]const u8 = null,
            size_vram: ?u64 = null,
        };

        models: []Model,
    };
    pub const ps = struct {
        pub const Model = struct {
            name: []const u8,
            model: []const u8,
            size: u64,
            digest: []const u8,
            details: ModelDetails,
            expires_at: ?[]const u8 = null,
            size_vram: ?u64 = null,
        };

        models: []Model,
    };

    pub const show = struct {
        modified_at: ?i64 = null,
        template: ?[]const u8 = null,
        modelfile: ?[]const u8 = null,
        license: ?[]const u8 = null,
        details: ?ModelDetails = null,
        model_info: ?std.StringHashMap(json.Value) = null,
        parameters: ?[]const u8 = null,
    };

    pub const status = struct {
        status: ?[]const u8 = null,
    };

    pub const progress = struct {
        status: ?[]const u8 = null,
        completed: ?u64 = null,
        total: ?u64 = null,
        digest: ?[]const u8 = null,
    };
};

pub const ModelDetails = struct {
    parent_model: ?[]const u8 = null,
    format: ?[]const u8 = null,
    family: ?[]const u8 = null,
    families: ?[][]const u8 = null,
    parameter_size: ?[]const u8 = null,
    quantization_level: ?[]const u8 = null,
};
