# Exline Programming Language v0.2.0

**Exline** is an object‑oriented, open-source, interpreted programming language that combines Ruby‑inspired readability with Rust‑class performance and safety. The language and interpreter is built with Rust.

**Readable like Ruby** and **Fast like Rust**

## Features Implemented (v0.2.0)

✅ **Variables and Basic Operations**
```exl
Int n1 = 1
Int n2 = 1
print(n1 + n2)  # Output: 2
```

✅ **Method Definitions and Flow Control**
```exl
def execute(name: String) -> String
  if name == "Exline"
    "Hello world, #{name}!"
  else
    "Hello Stranger!"
  end
end

print(execute("Exline"))  # Output: Hello world, Exline!
```

✅ **Object-Oriented Programming with Ruby-like Syntax**
```exl
interface Greetable
    def greet() : String
end

class Person implements Greetable
    String name
    Int age

    def greet() : void
        print("Hello from Person!")
    end

    def info() : void
        print("Person object created")
    end
end

p = Person.new()        # Ruby-like instantiation
p.greet()              # Output: Hello from Person!
p.info()               # Output: Person object created
print(p.name)          # Output: (empty string - default value)
print(p)               # Output: <Person object>
```

✅ **Type System and Safety**
- Strong type checking with Rust-inspired safety
- Custom classes with field definitions
- Interface implementation
- Runtime type verification

## Ruby-like Syntax Features

### Object Creation
```exl
# Ruby-style object instantiation
p = Person.new()     # Create using assignment

# Method calls work naturally
p.greet()           # Call methods on objects
p.info()            # Access object functionality
```

### Method Definitions with Return Types
```exl
# Explicit return type specification
def greet() : String    # Returns String type
def calculate() : Int   # Returns Integer type
def process() : void    # No return value
```

## Architecture

The Exline interpreter consists of three main components:

1. **Lexer** (`src/lexer.rs`) - Tokenizes source code into meaningful tokens
2. **Parser** (`src/parser.rs`) - Converts tokens into an Abstract Syntax Tree (AST)
3. **Interpreter** (`src/interpreter.rs`) - Executes the AST with runtime environment management

## Supported Features

### Data Types
- `Int` - 64-bit signed integers
- `String` - UTF-8 strings with basic interpolation support
- `void` - For methods that don't return values
- Custom types (classes)

### Operations
- Arithmetic: `+`, `-`, `*`, `/`
- Comparison: `==` (equality)
- String interpolation: `"Hello #{variable}!"`
- Object creation: `new ClassName()`
- Method calls: `object.method()`
- Field access: `object.field`

### Control Flow
- `if`/`else` statements
- Function definitions with parameters and return types

### Object-Oriented Features
- **Classes**: Define custom types with fields and methods
- **Interfaces**: Define contracts that classes can implement
- **Objects**: Create instances of classes with `new`
- **Method Calls**: Call methods on objects with dot notation
- **Field Access**: Access object fields with dot notation
- **Inheritance**: Classes can implement interfaces

### Built-in Functions
- `print(value)` - Outputs value to console

## Usage

### Compile and Run
```bash
cargo build --release
./target/release/exline your_program.exl
```

### REPL Mode
```bash
./target/release/exline
```

### Examples

**Basic arithmetic:**
```exl
Int a = 10
Int b = 5
print(a + b)    # 15
print(a * b)    # 50
print(a - b)    # 5
```

**Function with conditionals:**
```exl
def greet(name: String) -> String
  if name == "World"
    "Hello, #{name}!"
  else
    "Hi there!"
  end
end

print(greet("World"))  # Hello, World!
print(greet("Alice"))  # Hi there!
```

## Development

### Running Tests
```bash
cargo test
```

### Debug Mode
```bash
DEBUG_TOKENS=1 DEBUG_AST=1 ./target/debug/exline your_program.exl
```

## Design Goals

- **Modular**: Clean separation between lexer, parser, and interpreter
- **Performance-focused**: Built with Rust for efficiency
- **Type-safe**: Static typing with runtime type checking
- **Readable**: Ruby-inspired syntax with minimal punctuation

## Roadmap

Future versions will include:
- Classes and objects
- Advanced string interpolation
- More data types (Float, Boolean, Arrays)
- Error handling and exceptions
- Module system
- LLVM-based compilation for native performance

## License

Open source - see LICENSE file for details.
