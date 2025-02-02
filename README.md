# Ollama Zig Library

The Ollama Zig library provides the easiest way to integrate Zig 0.13+ projects with [Ollama](https://github.com/ollama/ollama).

## Prerequisites

- [Ollama](https://ollama.com/download) should be installed and running
- Pull a model to use with the library: `ollama pull <model>` e.g. `ollama pull llama3.2`
  - See [Ollama.com](https://ollama.com/search) for more information on the models available.

## Install

```sh
zig fetch --save git+https://github.com/dravenk/ollama-zig.git
```

## Usage

Adding to build.zig
```zig
    const ollama = b.dependency("ollama-zig", .{
        .target = target,
        .optimize = optimize,
    });
    exe.root_module.addImport("ollama", ollama.module("ollama"));
```

Import it in your code:
```zig 
const ollama = @import("ollama");
```

See [types.zig](src/types.zig) for more information on the response types.

## Streaming responses

Response streaming can be enabled by setting `.stream = true`.

```zig
try ollama.chat(.{ .model = "llama3.2", .stream = true, .messages = &.{
    .{ .role = .user, .content = "Why is the sky blue?" },
} });
```

## API

The Ollama Zig library's API is designed around the [Ollama REST API](https://github.com/ollama/ollama/blob/main/docs/api.md)

### Chat

```zig
    var responses = try ollama.chat(.{ .model = "llama3.2", .stream = false, .messages = &.{
        .{ .role = .user, .content = "Why is the sky blue?" },
    } });
    while (try responses.next()) |chat| {
        const content = chat.message.content;
        std.debug.print("{s}", .{content});
    }
```

### Generate

```zig
    var responses = try ollama.generate(.{ .model = "llama3.2", .prompt = "Why is the sky blue?" });
    while (try responses.next()) |response| {
        const content = response.response;
        std.debug.print("{s}", .{content});
    }

```

### Show

```zig
try ollama.show("llama3.2");
```

### Create

```zig
ollama.create(.{ .model = "mario", .from = "llama3.2", .system = "You are Mario from Super Mario Bros." });```

### Copy

```zig
ollama.copy("llama3.2", "user/llama3.2");
```

### Delete
(In plan)Wait for the upstream update. see https://github.com/ollama/ollama/issues/8753
```zig
ollama.delete("llama3.2")
```

### Pull

```zig
ollama.pull("llama3.2")
```

### Push

```zig
try ollama.push(.{ .model = "dravenk/llama3.2"});
```

### Embed or Embed (batch)

```zig
    var input = std.ArrayList([]const u8).init(allocator);
    try input.append("The sky is blue because of rayleigh scattering");
    try input.append("Grass is green because of chlorophyll");

    var responses = try ollama.embed(.{
        .model = "dravenk/llama3.2",
        .input = try input.toOwnedSlice(),
    });
    while (try responses.next()) |response| {
        std.debug.print("total_duration: {d}\n", .{response.total_duration.?});
        std.debug.print("prompt_eval_count: {d}\n", .{response.prompt_eval_count.?});
    }
```

### Ps

```zig
ollama.ps()
```
### Version

```zig
ollama.version()
```

## Errors

Errors are raised if requests return an error status or if an error is detected while streaming.

```zig
```
