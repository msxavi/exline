use crate::lexer::{Token, TokenType};

#[derive(Debug, Clone, PartialEq)]
pub enum Type {
    Int,
    String,
    Void,
    Custom(String), // For class types
}

#[derive(Debug, Clone, PartialEq)]
pub struct Parameter {
    pub name: String,
    pub param_type: Type,
}

#[derive(Debug, Clone, PartialEq)]
pub struct ClassField {
    pub name: String,
    pub field_type: Type,
}

#[derive(Debug, Clone, PartialEq)]
pub struct Method {
    pub name: String,
    pub parameters: Vec<Parameter>,
    pub return_type: Type,
    pub body: Vec<Statement>,
}

#[derive(Debug, Clone, PartialEq)]
pub struct InterfaceMethod {
    pub name: String,
    pub parameters: Vec<Parameter>,
    pub return_type: Type,
}

#[derive(Debug, Clone, PartialEq)]
pub enum Expression {
    Integer(i64),
    String(String),
    Identifier(String),
    Binary {
        left: Box<Expression>,
        operator: BinaryOperator,
        right: Box<Expression>,
    },
    FunctionCall {
        name: String,
        arguments: Vec<Expression>,
    },
    MethodCall {
        object: Box<Expression>,
        method: String,
        arguments: Vec<Expression>,
    },
    FieldAccess {
        object: Box<Expression>,
        field: String,
    },
    ObjectCreation {
        class_name: String,
    },
    StringInterpolation {
        parts: Vec<StringPart>,
    },
}

#[derive(Debug, Clone, PartialEq)]
pub enum StringPart {
    Literal(String),
    Expression(Expression),
}

#[derive(Debug, Clone, PartialEq)]
pub enum BinaryOperator {
    Add,
    Subtract,
    Multiply,
    Divide,
    Equal,
}

#[derive(Debug, Clone, PartialEq)]
pub enum Statement {
    VariableDeclaration {
        name: String,
        var_type: Type,
        value: Expression,
    },
    FunctionDefinition {
        name: String,
        parameters: Vec<Parameter>,
        return_type: Type,
        body: Vec<Statement>,
    },
    If {
        condition: Expression,
        then_branch: Vec<Statement>,
        else_branch: Option<Vec<Statement>>,
    },
    ClassDefinition {
        name: String,
        implements: Option<String>,
        fields: Vec<ClassField>,
        methods: Vec<Method>,
    },
    InterfaceDefinition {
        name: String,
        methods: Vec<InterfaceMethod>,
    },
    Assignment {
        target: Expression,
        value: Expression,
    },
    Expression(Expression),
}

#[derive(Debug)]
pub struct Program {
    pub statements: Vec<Statement>,
}

pub struct Parser {
    tokens: Vec<Token>,
    current: usize,
}

impl Parser {
    pub fn new(tokens: Vec<Token>) -> Self {
        Self { tokens, current: 0 }
    }

    pub fn parse(&mut self) -> Result<Program, String> {
        let mut statements = Vec::new();

        while !self.is_at_end() {
            // Skip newlines at the top level
            if self.check(&TokenType::Newline) {
                self.advance();
                continue;
            }

            statements.push(self.statement()?);
        }

        Ok(Program { statements })
    }

    fn statement(&mut self) -> Result<Statement, String> {
        if self.check(&TokenType::Int) || self.check(&TokenType::String_) {
            // Check if it's a variable declaration or custom type
            self.variable_or_custom_declaration()
        } else if self.check(&TokenType::Def) {
            self.function_definition()
        } else if self.check(&TokenType::If) {
            self.if_statement()
        } else if self.check(&TokenType::Class) {
            self.class_definition()
        } else if self.check(&TokenType::Interface) {
            self.interface_definition()
        } else {
            // Check if it's an assignment or expression
            let expr = self.expression()?;

            // Check if this is an assignment (field assignment)
            if self.check(&TokenType::Assign) {
                self.advance(); // consume =
                let value = self.expression()?;
                self.consume_newline_or_eof()?;
                Ok(Statement::Assignment {
                    target: expr,
                    value,
                })
            } else {
                self.consume_newline_or_eof()?;
                Ok(Statement::Expression(expr))
            }
        }
    }

    fn variable_or_custom_declaration(&mut self) -> Result<Statement, String> {
        let var_type = if self.check(&TokenType::Int) {
            self.advance();
            Type::Int
        } else if self.check(&TokenType::String_) {
            self.advance();
            Type::String
        } else if let TokenType::Identifier(type_name) = &self.peek().token_type {
            let type_name = type_name.clone();
            self.advance();
            Type::Custom(type_name)
        } else {
            return Err("Expected type".to_string());
        };

        let name = if let TokenType::Identifier(name) = &self.advance().token_type {
            name.clone()
        } else {
            return Err("Expected identifier".to_string());
        };

        if !self.check(&TokenType::Assign) {
            return Err("Expected '='".to_string());
        }
        self.advance();

        let value = self.expression()?;
        self.consume_newline_or_eof()?;

        Ok(Statement::VariableDeclaration {
            name,
            var_type,
            value,
        })
    }

    fn function_definition(&mut self) -> Result<Statement, String> {
        self.consume(&TokenType::Def, "Expected 'def'")?;

        let name = if let TokenType::Identifier(name) = &self.advance().token_type {
            name.clone()
        } else {
            return Err("Expected function name".to_string());
        };

        self.consume(&TokenType::LeftParen, "Expected '('")?;

        let mut parameters = Vec::new();
        if !self.check(&TokenType::RightParen) {
            loop {
                let param_name = if let TokenType::Identifier(name) = &self.advance().token_type {
                    name.clone()
                } else {
                    return Err("Expected parameter name".to_string());
                };

                // Expect colon
                self.consume(&TokenType::Colon, "Expected ':' after parameter name")?;

                let param_type = if self.check(&TokenType::Int) {
                    self.advance();
                    Type::Int
                } else if self.check(&TokenType::String_) {
                    self.advance();
                    Type::String
                } else {
                    return Err("Expected parameter type".to_string());
                };

                parameters.push(Parameter {
                    name: param_name,
                    param_type,
                });

                if self.check(&TokenType::RightParen) {
                    break;
                }
                // Skip any commas or other separators
                while !self.check(&TokenType::Identifier("".to_string())) && !self.check(&TokenType::RightParen) && !self.is_at_end() {
                    if let TokenType::Identifier(_) = self.peek().token_type {
                        break;
                    }
                    self.advance();
                }
            }
        }

        self.consume(&TokenType::RightParen, "Expected ')'")?;
        self.consume(&TokenType::Arrow, "Expected '->'")?;

        let return_type = if self.check(&TokenType::Int) {
            self.advance();
            Type::Int
        } else if self.check(&TokenType::String_) {
            self.advance();
            Type::String
        } else {
            return Err("Expected return type".to_string());
        };

        self.consume_newline_or_eof()?;

        let mut body = Vec::new();
        while !self.check(&TokenType::End) && !self.is_at_end() {
            if self.check(&TokenType::Newline) {
                self.advance();
                continue;
            }
            body.push(self.statement()?);
        }

        self.consume(&TokenType::End, "Expected 'end'")?;
        self.consume_newline_or_eof()?;

        Ok(Statement::FunctionDefinition {
            name,
            parameters,
            return_type,
            body,
        })
    }

    fn if_statement(&mut self) -> Result<Statement, String> {
        self.consume(&TokenType::If, "Expected 'if'")?;

        let condition = self.expression()?;
        self.consume_newline_or_eof()?;

        let mut then_branch = Vec::new();
        while !self.check(&TokenType::Else) && !self.check(&TokenType::End) && !self.is_at_end() {
            if self.check(&TokenType::Newline) {
                self.advance();
                continue;
            }
            then_branch.push(self.statement()?);
        }

        let else_branch = if self.check(&TokenType::Else) {
            self.advance();
            self.consume_newline_or_eof()?;

            let mut else_statements = Vec::new();
            while !self.check(&TokenType::End) && !self.is_at_end() {
                if self.check(&TokenType::Newline) {
                    self.advance();
                    continue;
                }
                else_statements.push(self.statement()?);
            }
            Some(else_statements)
        } else {
            None
        };

        self.consume(&TokenType::End, "Expected 'end'")?;
        self.consume_newline_or_eof()?;

        Ok(Statement::If {
            condition,
            then_branch,
            else_branch,
        })
    }

    fn class_definition(&mut self) -> Result<Statement, String> {
        self.consume(&TokenType::Class, "Expected 'class'")?;

        let name = if let TokenType::Identifier(name) = &self.advance().token_type {
            name.clone()
        } else {
            return Err("Expected class name".to_string());
        };

        // Check for implements clause
        let implements = if self.check(&TokenType::Implements) {
            self.advance();
            if let TokenType::Identifier(interface_name) = &self.advance().token_type {
                Some(interface_name.clone())
            } else {
                return Err("Expected interface name after 'implements'".to_string());
            }
        } else {
            None
        };

        self.consume_newline_or_eof()?;

        let mut fields = Vec::new();
        let mut methods = Vec::new();

        while !self.check(&TokenType::End) && !self.is_at_end() {
            if self.check(&TokenType::Newline) {
                self.advance();
                continue;
            }

            if self.check(&TokenType::Def) {
                // Parse method
                methods.push(self.parse_method()?);
            } else {
                // Parse field
                fields.push(self.parse_field()?);
            }
        }

        self.consume(&TokenType::End, "Expected 'end'")?;
        self.consume_newline_or_eof()?;

        Ok(Statement::ClassDefinition {
            name,
            implements,
            fields,
            methods,
        })
    }

    fn interface_definition(&mut self) -> Result<Statement, String> {
        self.consume(&TokenType::Interface, "Expected 'interface'")?;

        let name = if let TokenType::Identifier(name) = &self.advance().token_type {
            name.clone()
        } else {
            return Err("Expected interface name".to_string());
        };

        self.consume_newline_or_eof()?;

        let mut methods = Vec::new();

        while !self.check(&TokenType::End) && !self.is_at_end() {
            if self.check(&TokenType::Newline) {
                self.advance();
                continue;
            }

            methods.push(self.parse_interface_method()?);
        }

        self.consume(&TokenType::End, "Expected 'end'")?;
        self.consume_newline_or_eof()?;

        Ok(Statement::InterfaceDefinition {
            name,
            methods,
        })
    }

    fn parse_field(&mut self) -> Result<ClassField, String> {
        let field_type = self.parse_type()?;

        let name = if let TokenType::Identifier(name) = &self.advance().token_type {
            name.clone()
        } else {
            return Err("Expected field name".to_string());
        };

        self.consume_newline_or_eof()?;

        Ok(ClassField {
            name,
            field_type,
        })
    }

    fn parse_method(&mut self) -> Result<Method, String> {
        self.consume(&TokenType::Def, "Expected 'def'")?;

        let name = if let TokenType::Identifier(name) = &self.advance().token_type {
            name.clone()
        } else {
            return Err("Expected method name".to_string());
        };

        self.consume(&TokenType::LeftParen, "Expected '('")?;

        let mut parameters = Vec::new();
        if !self.check(&TokenType::RightParen) {
            loop {
                let param_name = if let TokenType::Identifier(name) = &self.advance().token_type {
                    name.clone()
                } else {
                    return Err("Expected parameter name".to_string());
                };

                self.consume(&TokenType::Colon, "Expected ':' after parameter name")?;
                let param_type = self.parse_type()?;

                parameters.push(Parameter {
                    name: param_name,
                    param_type,
                });

                if self.check(&TokenType::RightParen) {
                    break;
                }
                // Skip commas or other separators
                while !self.check(&TokenType::Identifier("".to_string())) && !self.check(&TokenType::RightParen) && !self.is_at_end() {
                    if let TokenType::Identifier(_) = self.peek().token_type {
                        break;
                    }
                    self.advance();
                }
            }
        }

        self.consume(&TokenType::RightParen, "Expected ')'")?;
        self.consume(&TokenType::Colon, "Expected ':' before return type")?;
        let return_type = self.parse_type()?;

        self.consume_newline_or_eof()?;

        let mut body = Vec::new();
        while !self.check(&TokenType::End) && !self.is_at_end() {
            if self.check(&TokenType::Newline) {
                self.advance();
                continue;
            }
            body.push(self.statement()?);
        }

        self.consume(&TokenType::End, "Expected 'end'")?;
        self.consume_newline_or_eof()?;

        Ok(Method {
            name,
            parameters,
            return_type,
            body,
        })
    }

    fn parse_interface_method(&mut self) -> Result<InterfaceMethod, String> {
        self.consume(&TokenType::Def, "Expected 'def'")?;

        let name = if let TokenType::Identifier(name) = &self.advance().token_type {
            name.clone()
        } else {
            return Err("Expected method name".to_string());
        };

        self.consume(&TokenType::LeftParen, "Expected '('")?;

        let mut parameters = Vec::new();
        if !self.check(&TokenType::RightParen) {
            loop {
                let param_name = if let TokenType::Identifier(name) = &self.advance().token_type {
                    name.clone()
                } else {
                    return Err("Expected parameter name".to_string());
                };

                self.consume(&TokenType::Colon, "Expected ':' after parameter name")?;
                let param_type = self.parse_type()?;

                parameters.push(Parameter {
                    name: param_name,
                    param_type,
                });

                if self.check(&TokenType::RightParen) {
                    break;
                }
                // Skip commas or other separators
                while !self.check(&TokenType::Identifier("".to_string())) && !self.check(&TokenType::RightParen) && !self.is_at_end() {
                    if let TokenType::Identifier(_) = self.peek().token_type {
                        break;
                    }
                    self.advance();
                }
            }
        }

        self.consume(&TokenType::RightParen, "Expected ')'")?;
        self.consume(&TokenType::Colon, "Expected ':' before return type")?;
        let return_type = self.parse_type()?;

        self.consume_newline_or_eof()?;

        Ok(InterfaceMethod {
            name,
            parameters,
            return_type,
        })
    }

    fn parse_type(&mut self) -> Result<Type, String> {
        if self.check(&TokenType::Int) {
            self.advance();
            Ok(Type::Int)
        } else if self.check(&TokenType::String_) {
            self.advance();
            Ok(Type::String)
        } else if self.check(&TokenType::Void) {
            self.advance();
            Ok(Type::Void)
        } else if let TokenType::Identifier(type_name) = &self.advance().token_type {
            Ok(Type::Custom(type_name.clone()))
        } else {
            Err("Expected type".to_string())
        }
    }

    fn expression(&mut self) -> Result<Expression, String> {
        self.equality()
    }

    fn equality(&mut self) -> Result<Expression, String> {
        let mut expr = self.addition()?;

        while self.check(&TokenType::Equal) {
            self.advance();
            let right = self.addition()?;
            expr = Expression::Binary {
                left: Box::new(expr),
                operator: BinaryOperator::Equal,
                right: Box::new(right),
            };
        }

        Ok(expr)
    }

    fn addition(&mut self) -> Result<Expression, String> {
        let mut expr = self.multiplication()?;

        while self.check(&TokenType::Plus) || self.check(&TokenType::Minus) {
            let operator = match self.advance().token_type {
                TokenType::Plus => BinaryOperator::Add,
                TokenType::Minus => BinaryOperator::Subtract,
                _ => unreachable!(),
            };
            let right = self.multiplication()?;
            expr = Expression::Binary {
                left: Box::new(expr),
                operator,
                right: Box::new(right),
            };
        }

        Ok(expr)
    }

    fn multiplication(&mut self) -> Result<Expression, String> {
        let mut expr = self.primary()?;

        while self.check(&TokenType::Multiply) || self.check(&TokenType::Divide) {
            let operator = match self.advance().token_type {
                TokenType::Multiply => BinaryOperator::Multiply,
                TokenType::Divide => BinaryOperator::Divide,
                _ => unreachable!(),
            };
            let right = self.primary()?;
            expr = Expression::Binary {
                left: Box::new(expr),
                operator,
                right: Box::new(right),
            };
        }

        Ok(expr)
    }

    fn primary(&mut self) -> Result<Expression, String> {
        let token = self.advance().clone();
        let mut expr = match &token.token_type {
            TokenType::Integer(value) => Ok(Expression::Integer(*value)),
            TokenType::String(value) => self.parse_string_with_interpolation(value.clone()),
            TokenType::Identifier(name) => {
                if self.check(&TokenType::LeftParen) {
                    // Function call
                    self.advance(); // consume (
                    let mut arguments = Vec::new();

                    if !self.check(&TokenType::RightParen) {
                        loop {
                            arguments.push(self.expression()?);
                            if self.check(&TokenType::RightParen) {
                                break;
                            }
                            // For now, we'll be lenient about comma separation
                        }
                    }

                    self.consume(&TokenType::RightParen, "Expected ')'")?;

                    Ok(Expression::FunctionCall {
                        name: name.clone(),
                        arguments,
                    })
                } else {
                    Ok(Expression::Identifier(name.clone()))
                }
            }
            TokenType::LeftParen => {
                let expr = self.expression()?;
                self.consume(&TokenType::RightParen, "Expected ')'")?;
                Ok(expr)
            }
            _ => Err("Expected expression".to_string()),
        }?;

        // Handle dot notation for method calls and field access
        while self.check(&TokenType::Dot) {
            self.advance(); // consume dot

            if let TokenType::Identifier(name) = &self.peek().token_type {
                let field_or_method_name = name.clone();
                self.advance(); // consume identifier

                if self.check(&TokenType::LeftParen) {
                    // Method call or object creation
                    self.advance(); // consume (
                    let mut arguments = Vec::new();

                    if !self.check(&TokenType::RightParen) {
                        loop {
                            arguments.push(self.expression()?);
                            if self.check(&TokenType::RightParen) {
                                break;
                            }
                        }
                    }

                    self.consume(&TokenType::RightParen, "Expected ')'")?;

                    // Check if this is ClassName.new() - treat as object creation
                    if field_or_method_name == "new" {
                        if let Expression::Identifier(class_name) = expr {
                            expr = Expression::ObjectCreation {
                                class_name,
                            };
                        } else {
                            return Err("'new' can only be called on class names".to_string());
                        }
                    } else {
                        // Regular method call
                        expr = Expression::MethodCall {
                            object: Box::new(expr),
                            method: field_or_method_name,
                            arguments,
                        };
                    }
                } else {
                    // Field access
                    expr = Expression::FieldAccess {
                        object: Box::new(expr),
                        field: field_or_method_name,
                    };
                }
            } else {
                return Err("Expected identifier after '.'".to_string());
            }
        }

        Ok(expr)
    }

    fn parse_string_with_interpolation(&mut self, value: String) -> Result<Expression, String> {
        // Simple implementation - check if string contains #{...}
        if value.contains("#{") {
            // For now, just return the string as-is and handle interpolation in interpreter
            Ok(Expression::String(value))
        } else {
            Ok(Expression::String(value))
        }
    }

    fn consume(&mut self, token_type: &TokenType, message: &str) -> Result<(), String> {
        if self.check(token_type) {
            self.advance();
            Ok(())
        } else {
            Err(message.to_string())
        }
    }

    fn consume_newline_or_eof(&mut self) -> Result<(), String> {
        if self.check(&TokenType::Newline) || self.check(&TokenType::Eof) {
            if !self.is_at_end() {
                self.advance();
            }
            Ok(())
        } else {
            Ok(()) // Be lenient for now
        }
    }

    fn check(&self, token_type: &TokenType) -> bool {
        if self.is_at_end() {
            false
        } else {
            match (token_type, &self.peek().token_type) {
                (TokenType::Colon, TokenType::Colon) => true,
                _ => std::mem::discriminant(&self.peek().token_type) == std::mem::discriminant(token_type)
            }
        }
    }

    fn advance(&mut self) -> &Token {
        if !self.is_at_end() {
            self.current += 1;
        }
        self.previous()
    }

    fn is_at_end(&self) -> bool {
        self.current >= self.tokens.len() || self.peek().token_type == TokenType::Eof
    }

    fn peek(&self) -> &Token {
        &self.tokens[self.current]
    }

    fn previous(&self) -> &Token {
        &self.tokens[self.current - 1]
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::lexer::Lexer;

    #[test]
    fn test_variable_declaration() {
        let mut lexer = Lexer::new("Int n1 = 1");
        let tokens = lexer.tokenize().unwrap();
        let mut parser = Parser::new(tokens);
        let program = parser.parse().unwrap();

        assert_eq!(program.statements.len(), 1);
        if let Statement::VariableDeclaration { name, var_type, .. } = &program.statements[0] {
            assert_eq!(name, "n1");
            assert_eq!(*var_type, Type::Int);
        } else {
            panic!("Expected variable declaration");
        }
    }

    #[test]
    fn test_arithmetic_expression() {
        let mut lexer = Lexer::new("n1 + n2");
        let tokens = lexer.tokenize().unwrap();
        let mut parser = Parser::new(tokens);
        let program = parser.parse().unwrap();

        assert_eq!(program.statements.len(), 1);
        if let Statement::Expression(Expression::Binary { operator, .. }) = &program.statements[0] {
            assert_eq!(*operator, BinaryOperator::Add);
        } else {
            panic!("Expected binary expression");
        }
    }
}