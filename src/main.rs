mod lexer;
mod parser;
mod interpreter;

#[cfg(test)]
mod debug;

use lexer::Lexer;
use parser::Parser;
use interpreter::Interpreter;
use std::env;
use std::fs;
use std::io::{self, Write};

fn main() {
    let args: Vec<String> = env::args().collect();

    if args.len() > 2 {
        eprintln!("Usage: {} [file.exl]", args[0]);
        std::process::exit(64);
    } else if args.len() == 2 {
        run_file(&args[1]);
    } else {
        run_repl();
    }
}

fn run_file(path: &str) {
    let source = match fs::read_to_string(path) {
        Ok(content) => content,
        Err(err) => {
            eprintln!("Error reading file '{}': {}", path, err);
            std::process::exit(74);
        }
    };

    if let Err(err) = run(&source) {
        eprintln!("Error: {}", err);
        std::process::exit(70);
    }
}

fn run_repl() {
    println!("Exline v0.1.0 REPL");
    println!("Type 'exit' to quit");

    loop {
        print!("> ");
        io::stdout().flush().unwrap();

        let mut input = String::new();
        match io::stdin().read_line(&mut input) {
            Ok(_) => {
                let input = input.trim();
                if input == "exit" {
                    break;
                }

                if input.is_empty() {
                    continue;
                }

                if let Err(err) = run(input) {
                    eprintln!("Error: {}", err);
                }
            }
            Err(err) => {
                eprintln!("Error reading input: {}", err);
                break;
            }
        }
    }
}

fn run(source: &str) -> Result<(), String> {
    // Tokenize
    let mut lexer = Lexer::new(source);
    let tokens = lexer.tokenize().map_err(|e| format!("Lexer error: {}", e))?;

    // Debug: print tokens
    if std::env::var("DEBUG_TOKENS").is_ok() {
        println!("Tokens:");
        for (i, token) in tokens.iter().enumerate() {
            println!("  {}: {:?}", i, token.token_type);
        }
    }

    // Parse
    let mut parser = Parser::new(tokens);
    let program = parser.parse().map_err(|e| format!("Parser error: {}", e))?;

    // Debug: print AST
    if std::env::var("DEBUG_AST").is_ok() {
        println!("AST: {:#?}", program);
    }

    // Interpret
    let mut interpreter = Interpreter::new();
    interpreter.interpret(program).map_err(|e| format!("Runtime error: {}", e))?;

    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_basic_program() {
        let source = r#"
Int n1 = 1
Int n2 = 1
print(n1 + n2)
"#;

        let result = run(source);
        assert!(result.is_ok());
    }

    #[test]
    fn test_string_variables() {
        let source = r#"
String name = "Exline"
print(name)
"#;

        let result = run(source);
        assert!(result.is_ok());
    }
}