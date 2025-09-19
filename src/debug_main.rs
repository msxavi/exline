use std::env;

mod lexer;
mod parser;
mod interpreter;

use lexer::Lexer;

fn main() {
    let args: Vec<String> = env::args().collect();

    if args.len() > 1 && args[1] == "debug-tokens" {
        if args.len() < 3 {
            eprintln!("Usage: {} debug-tokens <source>");
            return;
        }

        let source = &args[2];
        let mut lexer = Lexer::new(source);
        match lexer.tokenize() {
            Ok(tokens) => {
                println!("Tokens for: {}", source);
                for token in tokens {
                    println!("  {:?}", token);
                }
            }
            Err(e) => {
                eprintln!("Lexer error: {}", e);
            }
        }
        return;
    }

    // Rest of main function...
    println!("Exline v0.1.0");
    println!("Usage: exline [file.exl] or exline debug-tokens \"source code\"");
}