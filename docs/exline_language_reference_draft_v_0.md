# Exline Language Reference (Draft v0.1)

> **Status:** Early draft. Syntax stabilising. This document captures the authoritative intent for Exline and may diverge from prototype tooling.

---

## 1. Overview
**Exline** is an object‑oriented, compiled programming language that combines Ruby‑inspired readability with Rust‑class performance and safety. The compiler and toolchain are implemented in Rust. Exline favours an OO model with explicit interfaces, while offering modern features such as pattern matching, generics with protocol constraints, async/await, and an ownership/borrowing memory model—without a default GC.

**Key properties**
- **Paradigm:** OO‑first, multi‑paradigm.
- **Performance:** Ahead‑of‑time native compilation (LLVM/Cranelift). Zero‑cost abstractions.
- **Safety:** Ownership & borrowing; deterministic destruction (RAII); no default GC.
- **Ergonomics:** Ruby‑like syntax (minimal punctuation, blocks, interpolation).
- **Typing:** Optional static typing for **primitive values**; **mandatory annotations** for **complex structures** (classes, interfaces, public fields) and **method return types**.
- **Interfaces:** Contracts without implementation (akin to Java interfaces). Opt‑in dynamic dispatch with `Dyn[Interface]`.

---

## 2. Design Goals & Lineage
- **Readable like Ruby:** `def/end`, string interpolation, clean blocks.
- **Fast like Rust:** deterministic memory, zero‑cost generics/traits, LTO.
- **OO done right:** classes + mixins + interfaces; protocols for static polymorphism.
- **Predictable types:** inference for locals of primitive types; explicit types where it matters (APIs, class layout, interfaces, return types).

---

## 3. Source Files, Modules & Packages
- **File extension:** `.exl`
- **Module:**
  ```exline
  module Math:Geo
    # declarations
  end
  ```
  Namespaces use `:` separators. `use` imports qualified names:
  ```exline
  use Math:Geo:Point
  ```
- **Package manifest:** `Exline.toml`

---

## 4. Lexical Conventions
- **Whitespace & newlines** are significant as statement separators; semicolons optional.
- **Comments:** `# line comment`. (Block comments `=begin/=end` may be added later.)
- **Identifiers:** `A..Z, a..z, _` followed by alphanumerics/underscore. Case‑sensitive.
- **Literals:** `123`, `3.14`, `true/false`, `"string"` (UTF‑8), `b".."` (bytes planned).
- **Keywords (subset):** `module, class, interface, mixin, include, def, end, if, else, match, enum, let, var, use, return, async, await, actor`.

---

## 5. Type System
- **Primitive types:** `Bool, Int{8,16,32,64,128}, UInt{...}, Float{32,64}, Char, Byte, String`.
- **Composite types:** `Array[T]`, `Map[K,V]`, `Tuple[...]`, `Option[T]`, `Result[T,E]`.
- **User types:** `class`, `struct` (POD), `enum`.
- **Optional typing for primitives:** Local variables holding primitive values may omit type annotations; the compiler infers them.
- **Mandatory typing for complex structures:**
  - Class field types must be explicit.
  - Interface method signatures must be fully typed.
  - **All methods must specify an explicit return type.**
  - Public function signatures in library packages should specify types for clarity (recommended; tools may enforce).
- **Generics:** `Foo[T]`, with constraints `T: Protocol`.

Examples:
```exline
# Optional type for primitive locals
let n = 42        # inferred Int
var name = "Ana"  # inferred String, mutable local

# Explicit in APIs
def parse_u32(s: String) -> Result[UInt32, ParseError]
  # ...
end
```

---

## 6. Variables, Values & Mutability
- **Binding keywords:**
  - `let` — immutable binding (preferred).
  - `var` — mutable binding.
- **Assignment:** `=`
- **Shadowing:** Allowed within a narrower scope.

```exline
let x = 10
var y = x + 1
y = 99  # ok; `y` is mutable
```

---

## 7. Functions & Methods
- **Function:**
  ```exline
  def add(a: Int, b: Int) -> Int
    a + b
  end
  ```
- **Methods (return type required):**
  ```exline
  class Counter
    def initialize(start: Int) -> Void
      @n = start
    end

    def inc(delta: Int) -> Int
      @n = @n + delta
      @n
    end
  end
  ```
- **Overloading:** By arity and type (compile‑time resolution). Name‑only overloading is not allowed.
- **Default args & blocks:** Planned; blocks follow Ruby conventions.

---

## 8. Classes, Fields & Mixins
- **Class basics:**
  ```exline
  class User
    # explicit field types
    @id: Int
    @name: String

    def initialize(id: Int, name: String) -> Void
      @id = id; @name = name
    end

    def full_name() -> String
      @name
    end
  end
  ```
- **Visibility:** `pub` for public; private by default. (Granular rules TBA.)
- **Mixins:** Code reuse via `mixin` and `include` (no state added by mixins).
  ```exline
  mixin Timestamped
    def timestamp() -> Time
      Time.now
    end
  end

  class Loggable include Timestamped
    def last_seen() -> Time
      timestamp()
    end
  end
  ```

---

## 9. Interfaces (Java‑style contracts)
Interfaces define **contracts without implementation**. They may not contain fields or method bodies.

```exline
interface Serializer
  def serialize(x: Any) -> String
end

class JsonWriter : Serializer
  def serialize(x: Any) -> String
    # ...
  end
end
```
- **Dynamic dispatch:** Use `Dyn[Serializer]` to hold interface‑typed values at runtime.
- **No default methods:** By design—interfaces are pure contracts like Java; use **mixins** or **protocols** for shared implementations.

---

## 10. Protocols (static polymorphism)
Protocols express capabilities for generics and compile to static dispatch. Unlike interfaces, a protocol **may** provide default methods (subject to final design; defaults intended to be allowed here).

```exline
protocol Hashable
  def hash() -> Int
end

def dedup[T: Hashable](xs: Array[T]) -> Array[T]
  # ...
end
```

---

## 11. Enums & Pattern Matching
```exline
enum Result[T,E]
  Ok(T)
  Err(E)
end

match parse_u32("42")
  Ok(n)  => print "n=#{n}"
  Err(e) => print "parse error: #{e.message}"
end
```

---

## 12. Memory Model: Ownership & Borrowing
- **Move semantics** for owned values.
- **Borrows:** `&T` (shared), `&mut T` (unique/mutable).
- **Lifetimes** are inferred (non‑lexical regions); annotations appear only when needed in APIs.

```exline
class Buffer
  @data: Array[Byte]

  def initialize(cap: Int) -> Void
    @data = Array[Byte].with_capacity(cap)
  end

  def write(&mut self, bytes: &[Byte]) -> Result[Int, IOError]
    # ... mutate via unique borrow
  end

  def checksum(self: &Buffer) -> UInt32
    # ... read‑only borrow
  end
end
```

---

## 13. Errors & Control Flow
- No exceptions for normal control flow; prefer `Result[T,E]`.
- The `?` operator propagates errors.

```exline
def copy_file(src: Path, dst: Path) -> Result[Void, IOError]
  in  = File.open(src, Read)?
  out = File.open(dst, Write)?
  out.write_all(in.read_all()?)?
  Ok(Void)
end
```

---

## 14. Concurrency
- **async/await** for futures.
- **Actors** and channels for message‑passing.
- **Send/Sync‑like auto‑traits** derived from field types ensure data‑race freedom.

```exline
actor Mailbox[T]
  def send(msg: T) -> Void
  def recv() -> Async[Option[T]]
end
```

---

## 15. Modules, Imports & Visibility
- `module A:B` establishes a nested namespace.
- `use A:B:Type` imports a name.
- `pub` marks declarations as public to the package or module (scoping rules to be finalised).

---

## 16. Packages & Tooling
- **Manifest:** `Exline.toml`
- **CLI:** `exl` (package manager/workspace), `exlc` (compiler front‑end). Typical commands:
  - `exl new app`
  - `exl build` / `exl run`
  - `exl test` / `exl fmt` / `exl doc`
- **Install:** curl installer that fetches prebuilt binaries and falls back to building from source when necessary.

---

## 17. Interoperability (FFI)
```exline
extern "c" {
  def malloc(size: UInt64) -> Ptr[Void]
}
```

---

## 18. Standard Library (preview)
- **Core:** `Option, Result, Box, Rc, Arc, Slice`
- **Collections:** `Array, Map, Set`
- **IO:** `File, Reader, Writer`
- **Time/Net:** `Time, Duration, Socket`
- **Concurrency:** `Async, Chan, actor` runtime (library‑provided)

---

## 19. Examples
### 19.1 Hello, Exline!
```exline
def main
  print "Hello, Exline!"
end
```

### 19.2 Class + Interface
```exline
interface Greeter
  def greet() -> String
end

class Hello : Greeter
  @name: String
  def initialize(name: String) -> Void; @name = name; end
  def greet() -> String; "Hello, #{@name}"; end
end

def main
  g: Dyn[Greeter] = Hello.new("World")
  print g.greet()
end
```

### 19.3 Protocol‑constrained Generic
```exline
protocol Summable
  def zero() -> Self
  def add(self, other: Self) -> Self
end

def sum_all[T: Summable](xs: Array[T]) -> T
  let acc = T.zero()
  for x in xs; acc = acc.add(x); end
  acc
end
```

### 19.4 Errors & `?`
```exline
def run() -> Result[Void, IOError]
  data = File.read_to_string("config.ini")?
  print data
  Ok(Void)
end
```

### 19.5 Async fetch (sketch)
```exline
async def fetch(url: String) -> Bytes
  # ...
end

def main
  let body = await fetch("https://exline.dev")
  print "len=#{body.len()}"
end
```

---

## 20. Grammar Sketch (EBNF, illustrative)
```
program     := { module | class | interface | mixin | def } ;
module      := 'module' QName nl block 'end' ;
class       := 'class' Ident [ ':' SuperList ] nl class_body 'end' ;
interface   := 'interface' Ident nl interface_body 'end' ;
mixin       := 'mixin' Ident nl mixin_body 'end' ;

def         := 'def' Ident param_list [ '->' Type ] nl block 'end' ;
# Methods must specify return type; parser enforces in class/interface bodies.

param_list  := '(' [ param { ',' param } ] ')' ;
param       := Ident ':' Type ;

stmt        := let | var | assign | expr | if | match | while | return ;
let         := 'let' Ident [ ':' Type ] '=' expr ;
var         := 'var' Ident [ ':' Type ] '=' expr ;

Type        := QName [ '[' Type { ',' Type } ']' ] ;
QName       := Ident { ':' Ident } ;
```

---

## 21. Compliance With Stated Rules
- Exline is **OO**, **fast like Rust**, **built with Rust**.
- Syntax **inspired by Ruby**.
- **Optional static typing** for primitive locals; **mandatory** for complex structures (classes, interfaces, public fields) and **all method return types**.
- **Interfaces** are contracts **without implementation**, analogous to **Java interfaces**.

---

## 22. Roadmap Notes
- Stabilise mutability and visibility rules.
- Finalise protocol default methods.
- Flesh out actor runtime and `async` semantics.
- Define module/package visibility and friend semantics.
- Complete reference for pattern matching guards and destructuring.

---

## 23. Appendix: Terminology
- **Interface** — runtime contract (dynamic dispatch), no bodies.
- **Protocol** — compile‑time capability (static dispatch), may include defaults.
- **Mixin** — code reuse (no state), composed into classes.
- **Method** — function bound to a class; must have explicit return type.
- **Function** — top‑level routine; return type recommended.

