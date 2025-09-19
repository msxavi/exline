use std::fmt;

#[derive(Debug, Clone, PartialEq)]
pub enum TokenType {
    // Literals
    Integer(i64),
    String(String),
    Identifier(String),

    // Keywords
    Int,
    String_,  // String keyword
    Def,
    End,
    If,
    Else,
    Print,
    Class,
    Interface,
    Implements,
    New,
    Void,

    // Operators
    Plus,
    Minus,
    Multiply,
    Divide,
    Assign,
    Equal,

    // Delimiters
    LeftParen,
    RightParen,
    Arrow,      // ->
    Colon,      // :
    Dot,        // .

    // Special
    Newline,
    Eof,

    // String interpolation
    InterpolationStart,  // #{
    InterpolationEnd,    // }
}

#[derive(Debug, Clone)]
pub struct Token {
    pub token_type: TokenType,
    pub line: usize,
    pub column: usize,
}

impl Token {
    pub fn new(token_type: TokenType, line: usize, column: usize) -> Self {
        Self {
            token_type,
            line,
            column,
        }
    }
}

impl fmt::Display for Token {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
        write!(f, "{:?} at {}:{}", self.token_type, self.line, self.column)
    }
}

pub struct Lexer {
    input: Vec<char>,
    position: usize,
    line: usize,
    column: usize,
}

impl Lexer {
    pub fn new(input: &str) -> Self {
        Self {
            input: input.chars().collect(),
            position: 0,
            line: 1,
            column: 1,
        }
    }

    pub fn tokenize(&mut self) -> Result<Vec<Token>, String> {
        let mut tokens = Vec::new();

        while !self.is_at_end() {
            let token = self.next_token()?;
            tokens.push(token);
        }

        tokens.push(Token::new(TokenType::Eof, self.line, self.column));
        Ok(tokens)
    }

    fn next_token(&mut self) -> Result<Token, String> {
        self.skip_whitespace_except_newline();

        let line = self.line;
        let column = self.column;

        if self.is_at_end() {
            return Ok(Token::new(TokenType::Eof, line, column));
        }

        let ch = self.advance();

        match ch {
            '\n' => {
                self.line += 1;
                self.column = 1;
                Ok(Token::new(TokenType::Newline, line, column))
            }
            '+' => Ok(Token::new(TokenType::Plus, line, column)),
            '-' => {
                if self.peek() == '>' {
                    self.advance();
                    Ok(Token::new(TokenType::Arrow, line, column))
                } else {
                    Ok(Token::new(TokenType::Minus, line, column))
                }
            }
            '*' => Ok(Token::new(TokenType::Multiply, line, column)),
            '/' => Ok(Token::new(TokenType::Divide, line, column)),
            '=' => {
                if self.peek() == '=' {
                    self.advance(); // consume the second '='
                    Ok(Token::new(TokenType::Equal, line, column))
                } else {
                    Ok(Token::new(TokenType::Assign, line, column))
                }
            }
            '(' => Ok(Token::new(TokenType::LeftParen, line, column)),
            ')' => Ok(Token::new(TokenType::RightParen, line, column)),
            ':' => Ok(Token::new(TokenType::Colon, line, column)),
            '.' => Ok(Token::new(TokenType::Dot, line, column)),
            '"' => self.string_literal(line, column),
            '#' => {
                if self.peek() == '{' {
                    self.advance();
                    Ok(Token::new(TokenType::InterpolationStart, line, column))
                } else {
                    // Comment - skip to end of line
                    while self.peek() != '\n' && !self.is_at_end() {
                        self.advance();
                    }
                    self.next_token()
                }
            }
            '}' => Ok(Token::new(TokenType::InterpolationEnd, line, column)),
            _ if ch.is_ascii_digit() => self.number(line, column),
            _ if ch.is_alphabetic() || ch == '_' => self.identifier(line, column),
            _ => Err(format!("Unexpected character: {}", ch)),
        }
    }

    fn string_literal(&mut self, line: usize, column: usize) -> Result<Token, String> {
        let mut value = String::new();

        while self.peek() != '"' && !self.is_at_end() {
            if self.peek() == '\n' {
                self.line += 1;
                self.column = 1;
            }
            value.push(self.advance());
        }

        if self.is_at_end() {
            return Err("Unterminated string".to_string());
        }

        self.advance(); // closing "
        Ok(Token::new(TokenType::String(value), line, column))
    }

    fn number(&mut self, line: usize, column: usize) -> Result<Token, String> {
        let mut value = String::new();
        value.push(self.input[self.position - 1]); // Current character

        while self.peek().is_ascii_digit() {
            value.push(self.advance());
        }

        value.parse::<i64>()
            .map(|n| Token::new(TokenType::Integer(n), line, column))
            .map_err(|_| "Invalid number".to_string())
    }

    fn identifier(&mut self, line: usize, column: usize) -> Result<Token, String> {
        let mut value = String::new();
        value.push(self.input[self.position - 1]); // Current character

        while self.peek().is_alphanumeric() || self.peek() == '_' {
            value.push(self.advance());
        }

        let token_type = match value.as_str() {
            "Int" => TokenType::Int,
            "String" => TokenType::String_,
            "def" => TokenType::Def,
            "end" => TokenType::End,
            "if" => TokenType::If,
            "else" => TokenType::Else,
            "class" => TokenType::Class,
            "interface" => TokenType::Interface,
            "implements" => TokenType::Implements,
            "void" => TokenType::Void,
            // Remove "print" from keywords - it should be treated as identifier
            // Remove "new" from keywords - it should be treated as identifier (for Person.new() syntax)
            _ => TokenType::Identifier(value),
        };

        Ok(Token::new(token_type, line, column))
    }

    fn skip_whitespace_except_newline(&mut self) {
        while !self.is_at_end() {
            match self.peek() {
                ' ' | '\t' | '\r' => {
                    self.advance();
                }
                _ => break,
            }
        }
    }

    fn advance(&mut self) -> char {
        let ch = self.input[self.position];
        self.position += 1;
        self.column += 1;
        ch
    }

    fn peek(&self) -> char {
        if self.is_at_end() {
            '\0'
        } else {
            self.input[self.position]
        }
    }

    fn is_at_end(&self) -> bool {
        self.position >= self.input.len()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_basic_tokens() {
        let mut lexer = Lexer::new("Int n1 = 1");
        let tokens = lexer.tokenize().unwrap();

        assert_eq!(tokens[0].token_type, TokenType::Int);
        assert_eq!(tokens[1].token_type, TokenType::Identifier("n1".to_string()));
        assert_eq!(tokens[2].token_type, TokenType::Assign);
        assert_eq!(tokens[3].token_type, TokenType::Integer(1));
    }

    #[test]
    fn test_arithmetic() {
        let mut lexer = Lexer::new("n1 + n2");
        let tokens = lexer.tokenize().unwrap();

        assert_eq!(tokens[0].token_type, TokenType::Identifier("n1".to_string()));
        assert_eq!(tokens[1].token_type, TokenType::Plus);
        assert_eq!(tokens[2].token_type, TokenType::Identifier("n2".to_string()));
    }
}