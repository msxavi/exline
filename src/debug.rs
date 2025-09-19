use crate::lexer::Lexer;
use crate::parser::Parser;

fn debug_parsing(source: &str) {
    println!("=== Debugging: {} ===", source);

    // Tokenize
    let mut lexer = Lexer::new(source);
    match lexer.tokenize() {
        Ok(tokens) => {
            println!("Tokens:");
            for (i, token) in tokens.iter().enumerate() {
                println!("  {}: {:?}", i, token.token_type);
            }

            // Parse
            let mut parser = Parser::new(tokens);
            match parser.parse() {
                Ok(program) => {
                    println!("Parsed successfully!");
                    println!("AST: {:#?}", program);
                }
                Err(e) => {
                    println!("Parse error: {}", e);
                }
            }
        }
        Err(e) => {
            println!("Tokenize error: {}", e);
        }
    }
    println!();
}

#[cfg(test)]
mod debug_tests {
    use super::*;

    #[test]
    fn debug_simple_var() {
        debug_parsing("Int n1 = 1");
    }

    #[test]
    fn debug_arithmetic() {
        debug_parsing("n1 + n2");
    }

    #[test]
    fn debug_print() {
        debug_parsing("print(n1)");
    }

    #[test]
    fn debug_full_example() {
        debug_parsing("Int n1 = 1\nInt n2 = 1\nprint(n1 + n2)");
    }
}