namespace Boo.OMeta.Parser

import System.Globalization
import Boo.PatternMatching
import Boo.Lang.Compiler.Ast

def newMacro(name, args, body, m):
	node = MacroStatement(Name: tokenValue(name), Block: body, Modifier: m)
	for arg in args: node.Arguments.Add(arg)
	return node

def newSlicing(target as Expression, slices):
	node = SlicingExpression(Target: target)
	for slice in slices: node.Indices.Add(slice)
	return node
	
def newSlice(begin as Expression, end as Expression, step as Expression):
	return Slice(begin, end, step)

def newRValue(items as List):
	if len(items) > 1: return newArrayLiteral(items)
	return items[0]

def newForStatement(declarations, e as Expression, body as Block):
	node = ForStatement(Iterator: e, Block: body)
	for d in declarations: node.Declarations.Add(d)
	return node

def newDeclaration(name, type as TypeReference):
	return Declaration(Name: tokenValue(name), Type: type)

def newDeclarationStatement(d as Declaration,  initializer as Expression):
	return DeclarationStatement(Declaration: d, Initializer: initializer)

def newIfStatement(condition as Expression, trueBlock as Block):
	return IfStatement(Condition: condition, TrueBlock: trueBlock)
	
def newModule(doc, imports, members, stmts):
	m = Module(Documentation: doc)
	for item in imports: m.Imports.Add(item)
	for member in members: m.Members.Add(member)
	for stmt as Statement in stmts: m.Globals.Add(stmt)
	return m
	
def newImport(qname as string):
	return Import(Namespace: qname)

def newInteger(t, style as NumberStyles):
	value = int.Parse(tokenValue(t), style)
	return IntegerLiteralExpression(Value: value)
	
def newField(name, type, initializer):
	return Field(Name: tokenValue(name), Type: type, Initializer: initializer)
	
def newMethod(name, parameters, returnType as TypeReference, body as Block):
	node = Method(Name: tokenValue(name), Body: body, ReturnType: returnType)
	for p in parameters: node.Parameters.Add(p)
	return node
	
def newClass(name, baseTypes, members):
	return setUpType(ClassDefinition(Name: tokenValue(name)), baseTypes, members)
	
def setUpType(type as TypeDefinition, baseTypes, members):
	if members is not null: 
		for member in members: type.Members.Add(member)
	if baseTypes is not null:
		for baseType in baseTypes: type.BaseTypes.Add(baseType)
	return type
	
def newInterface(name, baseTypes, members):
	return setUpType(InterfaceDefinition(Name: tokenValue(name)), baseTypes, members)
	
def newInvocation(target as Expression, args as List):
	mie = MethodInvocationExpression(Target: target)
	for arg in args: mie.Arguments.Add(arg)
	return mie
	
def newQuasiquoteBlock(m as Module):
	return QuasiquoteExpression(Node: m)
	
def newQuasiquoteExpression(s as Statement):
	return QuasiquoteExpression(Node: s)
	
def newReference(t):
	return ReferenceExpression(Name: tokenValue(t))
	
def newMemberReference(target as Expression, name):
	return MemberReferenceExpression(Target: target, Name: tokenValue(name))
	
def newArrayLiteral(type, items):
	node = newArrayLiteral(items)
	node.Type = type
	return node
	
def newArrayLiteral(items):
	literal = ArrayLiteralExpression()
	for item in items:
		literal.Items.Add(item)
	return literal
	
def newListLiteral(items):
	literal = ListLiteralExpression()
	for item in items: literal.Items.Add(item)
	return literal
	
def newStringLiteral(s):
	return StringLiteralExpression(Value: tokenValue(s))
	
def newStringInterpolation(items as List):
	if len(items) == 1 and items[0] isa StringLiteralExpression:
		return items[0]
	node = ExpressionInterpolationExpression()
	for item in items: node.Expressions.Add(item)
	return node
	
def newInfixExpression(op, l as Expression, r as Expression):
	return BinaryExpression(Operator: binaryOperatorFor(op), Left: l, Right: r)
	
def newPrefixExpression(op, e as Expression):
	return UnaryExpression(Operator: unaryOperatorFor(op), Operand: e)
	
def unaryOperatorFor(op):
	match tokenValue(op):
		case "not": return UnaryOperatorType.LogicalNot
		case "-": return UnaryOperatorType.UnaryNegation
		case "~": return UnaryOperatorType.OnesComplement
		case "++": return UnaryOperatorType.Increment
		case "--": return UnaryOperatorType.Decrement
	
def binaryOperatorFor(op):
	match tokenValue(op):
		case "is": return BinaryOperatorType.ReferenceEquality
		case "is not": return BinaryOperatorType.ReferenceInequality
		case "in": return BinaryOperatorType.Member
		case "not in": return BinaryOperatorType.NotMember
		case "and": return BinaryOperatorType.And
		case "or": return BinaryOperatorType.Or
		case "|": return BinaryOperatorType.BitwiseOr
		case "&": return BinaryOperatorType.BitwiseAnd
		case "^": return BinaryOperatorType.ExclusiveOr
		case "+": return BinaryOperatorType.Addition
		case "-": return BinaryOperatorType.Subtraction
		case "*": return BinaryOperatorType.Multiply
		case "**": return BinaryOperatorType.Exponentiation
		case "/": return BinaryOperatorType.Division
		case "%": return BinaryOperatorType.Modulus
		case "=": return BinaryOperatorType.Assign
		case "==": return BinaryOperatorType.Equality
		case "!=": return BinaryOperatorType.Inequality
		case "+=": return BinaryOperatorType.InPlaceAddition
		case "-=": return BinaryOperatorType.InPlaceSubtraction
		case "/=": return BinaryOperatorType.InPlaceDivision
		case "*=": return BinaryOperatorType.InPlaceMultiply
		case "^=": return BinaryOperatorType.InPlaceExclusiveOr
		case "&=": return BinaryOperatorType.InPlaceBitwiseAnd
		case "|=": return BinaryOperatorType.InPlaceBitwiseOr
		case ">>": return BinaryOperatorType.ShiftRight
		case "<<": return BinaryOperatorType.ShiftLeft
		case "<": return BinaryOperatorType.LessThan
		case "<=": return BinaryOperatorType.LessThanOrEqual
		case ">": return BinaryOperatorType.GreaterThan
		case ">=": return BinaryOperatorType.GreaterThanOrEqual
	
def newAssignment(l as Expression, r as Expression):
	return [| $l = $r |]
	
def newBlock(stmts):
	b = Block()
	for item in stmts:
		b.Statements.Add(item)
	return b
	
def prepend(first, tail as List):
	if first is null: return tail
	return [first] + tail
	
def buildQName(q, rest):
	return join(tokenValue(t) for t in prepend(q, rest), '.')
