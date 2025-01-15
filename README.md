# Ollama Zig Library

The Ollama Zig library provides the easiest way to integrate Zig 1.13+ projects with [Ollama](https://github.com/ollama/ollama).

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

See [types.zig](ollama/src/types.zig) for more information on the response types.

## Streaming responses

Response streaming can be enabled by setting `stream=True`.

```zig
```

## API

The Ollama Zig library's API is designed around the [Ollama REST API](https://github.com/ollama/ollama/blob/main/docs/api.md)

### Chat

```zig
const message = &[_]Ollama.chatOptions.message{
    .{ .role = "user", .content = "Why is the sky blue?" },
};
const response = try ollama.chat(.{ .model = "llama3.2", .messages = message });
```

### Generate

```zig
ollama.generate(model='llama3.2', prompt='Why is the sky blue?')
```

### List

```zig
ollama.list()
```

### Show

```zig
ollama.show('llama3.2')
```

### Create

```zig
modelfile='''
FROM llama3.2
SYSTEM You are mario from super mario bros.
'''

ollama.create(model='example', modelfile=modelfile)
```

### Copy

```zig
ollama.copy('llama3.2', 'user/llama3.2')
```

### Delete

```zig
ollama.delete('llama3.2')
```

### Pull

```zig
ollama.pull('llama3.2')
```

### Push

```zig
ollama.push('user/llama3.2')
```

### Embed

```zig
ollama.embed(model='llama3.2', input='The sky is blue because of rayleigh scattering')
```

### Embed (batch)

```zig
ollama.embed(model='llama3.2', input=['The sky is blue because of rayleigh scattering', 'Grass is green because of chlorophyll'])
```

### Ps

```zig
ollama.ps()
```


## Errors

Errors are raised if requests return an error status or if an error is detected while streaming.

```zig
```
