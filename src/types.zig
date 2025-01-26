const std = @import("std");
// see: https://github.com/ollama/ollama-python/blob/main/ollama/_types.py

const Options = struct {
    // load time options
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

    // runtime options
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
    stop: ?[]const u8 = null,
};

const GenerateRequest = struct {
    model: []const u8,
    prompt: ?[]const u8 = null,
    suffix: ?[]const u8 = null,
    system: ?[]const u8 = null,
    template: ?[]const u8 = null,
    context: ?[]u8 = null,
    raw: ?bool = null,
    // format: ?Format = null,
    images: ?[]const u8 = null,
    options: ?Options = null,
    keep_alive: ?u64 = null,
};

const GenerateResponse = struct {
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
    response: []const u8,
    context: ?[]u8 = null,
};

const Message = struct {
    role: []const u8,
    content: ?[]const u8 = null,
    images: ?[]const u8 = null,
    tool_calls: ?[]ToolCall = null,
};

const ToolCall = struct {
    function: Function,
};

const Function = struct {
    name: []const u8,
    // arguments: std.StringHashMap(anytype),
};

const Tool = struct {
    type: ?[]const u8 = null,
    function: ?Function = null,
};

const EmbedRequest = struct {
    model: []const u8,
    input: []const u8,
    truncate: ?bool = null,
    options: ?Options = null,
    keep_alive: ?u64 = null,
};

const EmbedResponse = struct {
    embeddings: [][]f32,
};

const PullRequest = struct {
    model: []const u8,
    insecure: ?bool = null,
};

const PushRequest = struct {
    model: []const u8,
    insecure: ?bool = null,
};

const CreateRequest = struct {
    quantize: ?[]const u8 = null,
    from_: ?[]const u8 = null,
    files: ?std.StringHashMap([]const u8) = null,
    adapters: ?std.StringHashMap([]const u8) = null,
    template: ?[]const u8 = null,
    license: ?[]const u8 = null,
    system: ?[]const u8 = null,
    parameters: ?Options = null,
    messages: ?[]Message = null,
};

const ModelDetails = struct {
    parent_model: ?[]const u8 = null,
    format: ?[]const u8 = null,
    family: ?[]const u8 = null,
    families: ?[]const u8 = null,
    parameter_size: ?[]const u8 = null,
    quantization_level: ?[]const u8 = null,
};

const ListResponse = struct {
    models: []Model,
};

const Model = struct {
    model: ?[]const u8 = null,
    modified_at: ?[]const u8 = null,
    digest: ?[]const u8 = null,
    size: ?u64 = null,
    details: ?ModelDetails = null,
};

const DeleteRequest = struct {
    model: []const u8,
};

const CopyRequest = struct {
    source: []const u8,
    destination: []const u8,
};

const StatusResponse = struct {
    status: ?[]const u8 = null,
};

const ProgressResponse = struct {
    status: ?[]const u8 = null,
    completed: ?u64 = null,
    total: ?u64 = null,
    digest: ?[]const u8 = null,
};

const ShowRequest = struct {
    model: []const u8,
};

const ShowResponse = struct {
    modified_at: ?[]const u8 = null,
    template: ?[]const u8 = null,
    modelfile: ?[]const u8 = null,
    license: ?[]const u8 = null,
    details: ?ModelDetails = null,
    // modelinfo: ?std.StringHashMap(anytype) = null,
    parameters: ?[]const u8 = null,
};

const ProcessResponse = struct {
    models: []Model,
};

const RequestError = struct {
    Error: []const u8,
};

const ResponseError = struct {
    Error: []const u8,
    status_code: i32,
};
