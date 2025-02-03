const std = @import("std");
const Ollama = @import("ollama.zig").Ollama;

pub const Api = enum {
    // Generate a completion
    // see https://github.com/ollama/ollama/blob/main/docs/api.md#generate-a-completion
    // POST /api/generate
    generate,

    // Generate a chat completion
    // see https://github.com/ollama/ollama/blob/main/docs/api.md#generate-a-chat-completion
    // POST /api/chat
    chat,

    // Create a Model
    // see https://github.com/ollama/ollama/blob/main/docs/api.md#create-a-model
    // POST /api/create
    create,

    // TODO
    // Check if a Blob Exists
    // see https://github.com/ollama/ollama/blob/main/docs/api.md#check-if-a-blob-exists
    // HEAD /api/blobs/:digest
    head_blobs,

    // TODO
    // Push a Blob
    // see https://github.com/ollama/ollama/blob/main/docs/api.md#push-a-blob
    // POST /api/blobs/:digest
    push_blobs,

    // List Local Models
    // see https://github.com/ollama/ollama/blob/main/docs/api.md#list-local-models
    // GET /api/tags
    tags,

    // Show Model Information
    // see https://github.com/ollama/ollama/blob/main/docs/api.md#show-model-information
    // POST /api/show
    show,

    // Copy a Model
    // see https://github.com/ollama/ollama/blob/main/docs/api.md#copy-a-model
    // POST /api/copy
    copy,

    // Delete a Model
    // see https://github.com/ollama/ollama/blob/main/docs/api.md#delete-a-model
    // DELETE /api/delete
    delete,

    // Pull a Model
    // see https://github.com/ollama/ollama/blob/main/docs/api.md#pull-a-model
    // POST /api/pull
    pull,

    // Push a Model
    // see https://github.com/ollama/ollama/blob/main/docs/api.md#push-a-model
    // POST /api/push
    push,

    // Generate Embeddings
    // see https://github.com/ollama/ollama/blob/main/docs/api.md#generate-embeddings
    // POST /api/embed
    embed,

    // List Running Models
    // see https://github.com/ollama/ollama/blob/main/docs/api.md#list-running-models
    // GET /api/ps
    ps,

    // Generate Embedding
    // see https://github.com/ollama/ollama/blob/main/docs/api.md#generate-embedding
    // POST /api/embeddings
    embeddings,

    // Version
    // see https://github.com/ollama/ollama/blob/main/docs/api.md#version
    // GET /api/version
    version,

    pub fn method(api: Api) std.http.Method {
        switch (api) {
            .generate => return .POST,
            .chat => return .POST,
            .create => return .POST,
            .head_blobs => return .HEAD,
            .push_blobs => return .POST,
            .tags => return .GET,
            .show => return .POST,
            .copy => return .POST,
            .delete => return .DELETE,
            .pull => return .POST,
            .push => return .POST,
            .embed => return .POST,
            .ps => return .GET,
            .embeddings => return .POST,
            .version => return .GET,
        }
    }

    pub fn path(api: Api) []const u8 {
        switch (api) {
            .generate => return "/api/generate",
            .chat => return "/api/chat",
            .create => return "/api/create",
            .head_blobs => return "/api/blobs/:digest",
            .push_blobs => return "/api/blobs/:digest",
            .tags => return "/api/tags",
            .show => return "/api/show",
            .copy => return "/api/copy",
            .delete => return "/api/delete",
            .pull => return "/api/pull",
            .push => return "/api/push",
            .embed => return "/api/embed",
            .ps => return "/api/ps",
            .embeddings => return "/api/embeddings",
            .version => return "/api/version",
        }
    }
};
