const std = @import("std");
const Generate = @This();
const Ollama = @import("ollama.zig").Ollama;

const GenerateParameters = struct {
    model: []const u8,
    prompt: []const u8,
    suffix: ?[]const u8 = null,
    images: ?[]const u8 = null,
    format: ?Format = null,
    options: ?Options = null,
    system: ?[]const u8 = null,
    template: ?[]const u8 = null,
    stream: bool = true,
    raw: bool = false,
    keep_alive: ?u64 = null,
    context: ?[]const u8 = null,
};

const Format = enum {
    json,
    markdown,
    html,
    text,
};

const Options = struct {
    num_keep: ?u32 = null,
    seed: ?u32 = null,
    num_predict: ?u32 = null,
    top_k: ?u32 = null,
    top_p: ?f32 = null,
    min_p: ?f32 = null,
    typical_p: ?f32 = null,
    repeat_last_n: ?i32 = null,
    temperature: ?f32 = null,
    repeat_penalty: ?f32 = null,
    presence_penalty: ?f32 = null,
    frequency_penalty: ?f32 = null,
    mirostat: ?u32 = null,
    mirostat_tau: ?f32 = null,
    mirostat_eta: ?f32 = null,
    penalize_newline: ?bool = null,
    stop: ?[]const u8 = null,
    numa: ?bool = null,
    num_ctx: ?u32 = null,
    num_batch: ?u32 = null,
    num_gpu: ?u32 = null,
    main_gpu: ?u32 = null,
    low_vram: ?bool = null,
    vocab_only: ?bool = null,
    use_mmap: ?bool = null,
    use_mlock: ?bool = null,
    num_thread: ?u32 = null,
    tfs_z: ?f32 = null,
};

const GenerateResponse = struct {
    model: []const u8,
    created_at: []const u8,
    response: []const u8,
    done: bool,
    context: ?[]u8 = null,
    total_duration: u64,
    load_duration: u64,
    prompt_eval_count: u32,
    prompt_eval_duration: u64,
    eval_count: u32,
    eval_duration: u64,
    done_reason: ?[]const u8 = null,
    message: Message,
};

const Message = struct {
    role: []const u8,
    content: []const u8,
};

pub fn generate(self: *Ollama, options: GenerateParameters) !GenerateResponse {
    const request = GenerateRequest{
        .model = options.model,
        .prompt = options.prompt,
        .suffix = options.suffix,
        .system = options.system,
        .template = options.template,
        .context = options.context,
        .stream = options.stream,
        .raw = options.raw,
        .format = options.format,
        .images = options.images,
        .options = options.options,
        .keep_alive = options.keep_alive,
    };

    const response = try self.raw_request(
        GenerateResponse,
        .POST,
        "/api/generate",
        request,
        options.stream,
    );

    return response;
}

const GenerateRequest = struct {
    model: []const u8,
    prompt: []const u8,
    suffix: ?[]const u8 = null,
    system: ?[]const u8 = null,
    template: ?[]const u8 = null,
    context: ?[]const u8 = null,
    stream: bool = false,
    raw: ?bool = null,
    format: ?Format = null,
    images: ?[]const u8 = null,
    options: ?Options = null,
    keep_alive: ?u64 = null,

    pub fn raw_request(self: *GenerateRequest) !void {
        _ = self;
    }
};
