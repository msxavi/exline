use crate::parser::{Program, Statement, Expression, BinaryOperator, Type, Parameter, ClassField, Method};
use std::collections::HashMap;

#[derive(Debug, Clone, PartialEq)]
pub enum Value {
    Integer(i64),
    String(String),
    Function {
        parameters: Vec<Parameter>,
        return_type: Type,
        body: Vec<Statement>,
    },
    Object {
        class_name: String,
        fields: HashMap<String, Value>,
    },
    Void,
}

impl Value {
    pub fn type_name(&self) -> &'static str {
        match self {
            Value::Integer(_) => "Int",
            Value::String(_) => "String",
            Value::Function { .. } => "Function",
            Value::Object { class_name, .. } => "Object",
            Value::Void => "Void",
        }
    }

    pub fn to_string(&self) -> String {
        match self {
            Value::Integer(n) => n.to_string(),
            Value::String(s) => s.clone(),
            Value::Function { .. } => "<function>".to_string(),
            Value::Object { class_name, .. } => format!("<{} object>", class_name),
            Value::Void => "void".to_string(),
        }
    }
}

pub struct Environment {
    variables: HashMap<String, Value>,
    functions: HashMap<String, Value>,
    classes: HashMap<String, ClassDefinition>,
    interfaces: HashMap<String, InterfaceDefinition>,
}

#[derive(Debug, Clone)]
pub struct ClassDefinition {
    pub name: String,
    pub fields: Vec<ClassField>,
    pub methods: Vec<Method>,
    pub implements: Option<String>,
}

#[derive(Debug, Clone)]
pub struct InterfaceDefinition {
    pub name: String,
    pub methods: Vec<crate::parser::InterfaceMethod>,
}

impl Environment {
    pub fn new() -> Self {
        let mut env = Self {
            variables: HashMap::new(),
            functions: HashMap::new(),
            classes: HashMap::new(),
            interfaces: HashMap::new(),
        };

        // Add built-in print function
        env.functions.insert("print".to_string(), Value::Function {
            parameters: vec![Parameter {
                name: "value".to_string(),
                param_type: Type::String, // For simplicity, print takes any value
            }],
            return_type: Type::String,
            body: vec![], // Built-in functions have empty body
        });

        env
    }

    pub fn define_variable(&mut self, name: String, value: Value) {
        self.variables.insert(name, value);
    }

    pub fn get_variable(&self, name: &str) -> Option<&Value> {
        self.variables.get(name)
    }

    pub fn define_function(&mut self, name: String, value: Value) {
        self.functions.insert(name, value);
    }

    pub fn get_function(&self, name: &str) -> Option<&Value> {
        self.functions.get(name)
    }

    pub fn define_class(&mut self, name: String, class_def: ClassDefinition) {
        self.classes.insert(name, class_def);
    }

    pub fn get_class(&self, name: &str) -> Option<&ClassDefinition> {
        self.classes.get(name)
    }

    pub fn define_interface(&mut self, name: String, interface_def: InterfaceDefinition) {
        self.interfaces.insert(name, interface_def);
    }

    pub fn get_interface(&self, name: &str) -> Option<&InterfaceDefinition> {
        self.interfaces.get(name)
    }
}

pub struct Interpreter {
    environment: Environment,
}

impl Interpreter {
    pub fn new() -> Self {
        Self {
            environment: Environment::new(),
        }
    }

    pub fn interpret(&mut self, program: Program) -> Result<(), String> {
        for statement in program.statements {
            self.execute_statement(&statement)?;
        }
        Ok(())
    }

    fn execute_statement(&mut self, statement: &Statement) -> Result<Option<Value>, String> {
        match statement {
            Statement::VariableDeclaration { name, var_type, value } => {
                let val = self.evaluate_expression(value)?;

                // Type checking
                match (var_type, &val) {
                    (Type::Int, Value::Integer(_)) => {},
                    (Type::String, Value::String(_)) => {},
                    (Type::Void, Value::Void) => {},
                    (Type::Custom(class_name), Value::Object { class_name: obj_class, .. }) => {
                        if class_name != obj_class {
                            return Err(format!(
                                "Type mismatch: expected {}, got {}",
                                class_name,
                                obj_class
                            ));
                        }
                    },
                    _ => return Err(format!(
                        "Type mismatch: expected {:?}, got {}",
                        var_type,
                        val.type_name()
                    )),
                }

                self.environment.define_variable(name.clone(), val);
                Ok(None)
            }

            Statement::FunctionDefinition { name, parameters, return_type, body } => {
                let function_value = Value::Function {
                    parameters: parameters.clone(),
                    return_type: return_type.clone(),
                    body: body.clone(),
                };
                self.environment.define_function(name.clone(), function_value);
                Ok(None)
            }

            Statement::If { condition, then_branch, else_branch } => {
                let condition_value = self.evaluate_expression(condition)?;

                let should_execute_then = match condition_value {
                    Value::Integer(n) => n != 0,
                    Value::String(s) => !s.is_empty(),
                    Value::Function { .. } => true,
                    Value::Object { .. } => true,
                    Value::Void => false,
                };

                if should_execute_then {
                    for stmt in then_branch {
                        if let Some(return_value) = self.execute_statement(stmt)? {
                            return Ok(Some(return_value));
                        }
                    }
                } else if let Some(else_stmts) = else_branch {
                    for stmt in else_stmts {
                        if let Some(return_value) = self.execute_statement(stmt)? {
                            return Ok(Some(return_value));
                        }
                    }
                }
                Ok(None)
            }

            Statement::Expression(expr) => {
                let value = self.evaluate_expression(expr)?;
                Ok(Some(value))
            }

            Statement::ClassDefinition { name, fields, methods, implements } => {
                let class_def = ClassDefinition {
                    name: name.clone(),
                    fields: fields.clone(),
                    methods: methods.clone(),
                    implements: implements.clone(),
                };
                self.environment.define_class(name.clone(), class_def);
                Ok(None)
            }

            Statement::InterfaceDefinition { name, methods } => {
                let interface_def = InterfaceDefinition {
                    name: name.clone(),
                    methods: methods.clone(),
                };
                self.environment.define_interface(name.clone(), interface_def);
                Ok(None)
            }

            Statement::Assignment { target, value } => {
                let val = self.evaluate_expression(value)?;

                // For now, only support simple identifier assignments
                if let Expression::Identifier(name) = target {
                    self.environment.define_variable(name.clone(), val);
                    Ok(None)
                } else {
                    Err("Only simple variable assignments are supported currently".to_string())
                }
            }
        }
    }

    fn evaluate_expression(&mut self, expression: &Expression) -> Result<Value, String> {
        match expression {
            Expression::Integer(n) => Ok(Value::Integer(*n)),

            Expression::String(s) => {
                // Handle simple string interpolation #{variable}
                if s.contains("#{") {
                    let mut result = s.clone();
                    // Simple regex-like replacement for #{name}
                    if let Some(start) = result.find("#{") {
                        if let Some(end) = result.find('}') {
                            let var_name = &result[start + 2..end];
                            if let Some(value) = self.environment.get_variable(var_name) {
                                let replacement = value.to_string();
                                result.replace_range(start..=end, &replacement);
                            }
                        }
                    }
                    Ok(Value::String(result))
                } else {
                    Ok(Value::String(s.clone()))
                }
            }

            Expression::Identifier(name) => {
                if let Some(value) = self.environment.get_variable(name) {
                    Ok(value.clone())
                } else {
                    Err(format!("Undefined variable: {}", name))
                }
            }

            Expression::Binary { left, operator, right } => {
                let left_val = self.evaluate_expression(left)?;
                let right_val = self.evaluate_expression(right)?;

                match operator {
                    BinaryOperator::Add => self.add_values(left_val, right_val),
                    BinaryOperator::Subtract => self.subtract_values(left_val, right_val),
                    BinaryOperator::Multiply => self.multiply_values(left_val, right_val),
                    BinaryOperator::Divide => self.divide_values(left_val, right_val),
                    BinaryOperator::Equal => self.equal_values(left_val, right_val),
                }
            }

            Expression::FunctionCall { name, arguments } => {
                // Handle built-in print function
                if name == "print" {
                    if arguments.len() != 1 {
                        return Err("print() takes exactly one argument".to_string());
                    }

                    let value = self.evaluate_expression(&arguments[0])?;
                    println!("{}", value.to_string());
                    return Ok(Value::String("".to_string()));
                }

                // Handle user-defined functions
                if let Some(function) = self.environment.get_function(name).cloned() {
                    if let Value::Function { parameters, return_type, body } = function {
                        if arguments.len() != parameters.len() {
                            return Err(format!(
                                "Function {} expects {} arguments, got {}",
                                name,
                                parameters.len(),
                                arguments.len()
                            ));
                        }

                        // Create new scope for function execution
                        let old_vars = self.environment.variables.clone();

                        // Bind arguments to parameters
                        for (param, arg) in parameters.iter().zip(arguments.iter()) {
                            let arg_value = self.evaluate_expression(arg)?;

                            // Type checking
                            match (&param.param_type, &arg_value) {
                                (Type::Int, Value::Integer(_)) => {},
                                (Type::String, Value::String(_)) => {},
                                (Type::Void, Value::Void) => {},
                                (Type::Custom(class_name), Value::Object { class_name: obj_class, .. }) => {
                                    if class_name != obj_class {
                                        return Err(format!(
                                            "Argument type mismatch for parameter {}: expected {}, got {}",
                                            param.name,
                                            class_name,
                                            obj_class
                                        ));
                                    }
                                },
                                _ => return Err(format!(
                                    "Argument type mismatch for parameter {}: expected {:?}, got {}",
                                    param.name,
                                    param.param_type,
                                    arg_value.type_name()
                                )),
                            }

                            self.environment.define_variable(param.name.clone(), arg_value);
                        }

                        // Execute function body
                        let mut result = match return_type {
                            Type::Int => Value::Integer(0),
                            Type::String => Value::String("".to_string()),
                            Type::Void => Value::Void,
                            Type::Custom(_) => Value::Void, // Default for custom types
                        };

                        for stmt in &body {
                            if let Some(return_value) = self.execute_statement(stmt)? {
                                result = return_value;
                                break;
                            }
                        }

                        // Restore old scope
                        self.environment.variables = old_vars;

                        Ok(result)
                    } else {
                        unreachable!("Function value should be Function variant")
                    }
                } else {
                    Err(format!("Undefined function: {}", name))
                }
            }

            Expression::StringInterpolation { parts: _ } => {
                // TODO: Implement string interpolation
                Ok(Value::String("".to_string()))
            }

            Expression::MethodCall { object, method, arguments } => {
                let obj_value = self.evaluate_expression(object)?;

                if let Value::Object { class_name, fields } = obj_value {
                    if let Some(class_def) = self.environment.get_class(&class_name).cloned() {
                        // Find the method in the class
                        for method_def in &class_def.methods {
                            if method_def.name == *method {
                                // Check argument count
                                if arguments.len() != method_def.parameters.len() {
                                    return Err(format!(
                                        "Method {} expects {} arguments, got {}",
                                        method,
                                        method_def.parameters.len(),
                                        arguments.len()
                                    ));
                                }

                                // Create new scope for method execution
                                let old_vars = self.environment.variables.clone();

                                // Add 'this' reference
                                self.environment.define_variable("this".to_string(), Value::Object {
                                    class_name: class_name.clone(),
                                    fields: fields.clone(),
                                });

                                // Bind arguments to parameters
                                for (param, arg) in method_def.parameters.iter().zip(arguments.iter()) {
                                    let arg_value = self.evaluate_expression(arg)?;
                                    self.environment.define_variable(param.name.clone(), arg_value);
                                }

                                // Execute method body
                                let mut result = match &method_def.return_type {
                                    Type::Int => Value::Integer(0),
                                    Type::String => Value::String("".to_string()),
                                    Type::Void => Value::Void,
                                    Type::Custom(_) => Value::Void, // Default for custom types
                                };

                                for stmt in &method_def.body {
                                    if let Some(return_value) = self.execute_statement(stmt)? {
                                        result = return_value;
                                        break;
                                    }
                                }

                                // Restore old scope
                                self.environment.variables = old_vars;

                                return Ok(result);
                            }
                        }
                        Err(format!("Method {} not found in class {}", method, class_name))
                    } else {
                        Err(format!("Class {} not found", class_name))
                    }
                } else {
                    Err(format!("Cannot call method on non-object value"))
                }
            }

            Expression::FieldAccess { object, field } => {
                let obj_value = self.evaluate_expression(object)?;

                if let Value::Object { class_name: _, fields } = obj_value {
                    if let Some(field_value) = fields.get(field) {
                        Ok(field_value.clone())
                    } else {
                        Err(format!("Field {} not found", field))
                    }
                } else {
                    Err(format!("Cannot access field on non-object value"))
                }
            }

            Expression::ObjectCreation { class_name } => {
                if let Some(class_def) = self.environment.get_class(class_name).cloned() {
                    let mut fields = HashMap::new();

                    // Initialize fields with default values
                    for field in &class_def.fields {
                        let default_value = match &field.field_type {
                            Type::Int => Value::Integer(0),
                            Type::String => Value::String("".to_string()),
                            Type::Void => Value::Void,
                            Type::Custom(_) => Value::Void,
                        };
                        fields.insert(field.name.clone(), default_value);
                    }

                    // TODO: Handle constructor arguments
                    // For now, just create the object with default field values

                    Ok(Value::Object {
                        class_name: class_name.clone(),
                        fields,
                    })
                } else {
                    Err(format!("Class {} not found", class_name))
                }
            }
        }
    }

    fn add_values(&self, left: Value, right: Value) -> Result<Value, String> {
        match (left, right) {
            (Value::Integer(a), Value::Integer(b)) => Ok(Value::Integer(a + b)),
            (Value::String(a), Value::String(b)) => Ok(Value::String(a + &b)),
            (left, right) => Err(format!(
                "Cannot add {} and {}",
                left.type_name(),
                right.type_name()
            )),
        }
    }

    fn subtract_values(&self, left: Value, right: Value) -> Result<Value, String> {
        match (left, right) {
            (Value::Integer(a), Value::Integer(b)) => Ok(Value::Integer(a - b)),
            (left, right) => Err(format!(
                "Cannot subtract {} and {}",
                left.type_name(),
                right.type_name()
            )),
        }
    }

    fn multiply_values(&self, left: Value, right: Value) -> Result<Value, String> {
        match (left, right) {
            (Value::Integer(a), Value::Integer(b)) => Ok(Value::Integer(a * b)),
            (left, right) => Err(format!(
                "Cannot multiply {} and {}",
                left.type_name(),
                right.type_name()
            )),
        }
    }

    fn divide_values(&self, left: Value, right: Value) -> Result<Value, String> {
        match (left, right) {
            (Value::Integer(a), Value::Integer(b)) => {
                if b == 0 {
                    Err("Division by zero".to_string())
                } else {
                    Ok(Value::Integer(a / b))
                }
            }
            (left, right) => Err(format!(
                "Cannot divide {} and {}",
                left.type_name(),
                right.type_name()
            )),
        }
    }

    fn equal_values(&self, left: Value, right: Value) -> Result<Value, String> {
        let result = match (left, right) {
            (Value::Integer(a), Value::Integer(b)) => a == b,
            (Value::String(a), Value::String(b)) => a == b,
            _ => false,
        };
        Ok(Value::Integer(if result { 1 } else { 0 }))
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::lexer::Lexer;
    use crate::parser::Parser;

    #[test]
    fn test_variable_declaration_and_arithmetic() {
        let source = r#"
Int n1 = 1
Int n2 = 2
print(n1 + n2)
"#;

        let mut lexer = Lexer::new(source);
        let tokens = lexer.tokenize().unwrap();
        let mut parser = Parser::new(tokens);
        let program = parser.parse().unwrap();
        let mut interpreter = Interpreter::new();

        let result = interpreter.interpret(program);
        assert!(result.is_ok());
    }
}