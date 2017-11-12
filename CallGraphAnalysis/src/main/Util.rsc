module main::Util

import Prelude;
import lang::java::m3::Core;
import lang::java::m3::AST;
import lang::java::jdt::m3::Core;
import lang::java::m3::TypeHierarchy;
import lang::java::m3::TypeSymbol;

import analysis::m3::Core;
import main::M3Extensions;


/**
* Returns a list of all the call sites in a given method.
*/
public list[loc] getCallSites(loc method, M3 model)
{
	return [ x | <m,x> <- model.methodInvocation, m == method ]; 
}

/**
* Returns a set of all static methods, except constructors, present in the given M3 model.
*/
public set[loc] getStaticMethods(M3 model) 
{
	return { m | <m, modifier> <- model.modifiers, modifier == static() && m.scheme == "java+method" };
}

public set[loc] getStaticMethodsAndConstructors(M3 model)
{
	return getStaticMethods(model) + constructors(model);
}


/**
* Determines if a given method is static (i.e. is static or a constructor).
*/
public bool isStatic(loc method, M3 model) 
{
	return <method, static()> in model.modifiers
		|| method.scheme == "java+constructor";
}

/**
* Determines if a given method is protected.
*/
public bool isProtected(loc method, M3 model) 
{
	return <method, protected()> in model.modifiers;
}

/**
* Determines if a given method is public.
*/
public bool isPublic(loc method, M3 model) 
{
	return <method, \public()> in model.modifiers;
}

/**
* Determines if a given method is private.
*/
public bool isPrivate(loc method, M3 model) 
{
	return <method,\private()> in model.modifiers;
}

/*
* Obsolete: getDeclaredTypeHierarchy -> https://github.com/usethesource/rascal/blob/master/src/org/rascalmpl/library/lang/java/m3/TypeHierarchy.rsc
*
public rel[loc,loc] getClassInheritance(M3 model)
{
	return model.extends + model.implements;
}
*/

public rel[loc from, loc to] getDeclaredClassHierarchy(M3 model) 
{
     classesWithoutParent = classes(model) - model.extends<from>;
     
     classesWithoutParent -= |java+class:///java/lang/Object|;
     
     return classesWithoutParent * {|java+class:///java/lang/Object|} + model.extends;
}


public loc classOf(loc method, M3 model) 
{ 
	if(!isMethod(method)) 
		throw "Parameter \'method\' does not reference a method. Actual: <method>"; 
	

	// Note here that a method can be:
	// - a default contructor (not present in model.containment)
	// - a constructor of an anonymous class which is default by definition
	//   From the Java Language Specification, section 15.9.5.1: An anonymous class cannot have an explicitly declared constructor.
	//   Thus also not present in model.containment
	// - a constructor or method from an external class 
	
	classe = [ class | <class,y> <- model.containment, y == method ];
	
	if(size(classe) == 1) 
	{
		return classe[0];
	}
	else if(contains(method.parent.path, "$anonymous"))
	{
		return |java+anonymousClass:///<method.parent.path>|;
	}
	else
	{
		return |java+class:///<method.parent.path>|;
	}
}

public bool isSubTypeOf(loc subType, loc superType, M3 model) 
{
	return <subType, superType> in model.typeDependency+;
}

/**
* Returns the sub classes (direct and indirect) os a given class.
*/
public set[loc] subClassesOf(M3 model, loc class) 
{
	return { x | <x,y> <- model.typeDependency+, x.scheme == "java+class" && y == class };
}

public set[loc] getConeClassSet(M3 model, loc class)
{
	classSet = getDeclaredTypeHierarchy(model);
	
	// The transitive closure of classSet will give us all the direct and indirect
	// inheritance paths of each class.
	
	return class + { x | <x,y> <- classSet+, y == class };
}


/**
* Returns the name of a method from a given method location.
*/
public str getMethodName(M3 model, loc method) 
{
	return [ name | <name, m> <- model.names, m == method ][0];
}

/**
* Finds all the main methods.
*/
public set[loc] findMainMethods(M3 model) 
{
	// Select all methods with the name 'main'.
	set[loc] mainMethods = { method | <name,method> <- model.names, name == "main" && method.scheme == "java+method" };
	
	// Select methods that are both public and static.
	mainMethods = mainMethods & { method | <method,modifier> <- model.modifiers, modifier == static() };
	mainMethods = mainMethods & { method | <method,modifier> <- model.modifiers, modifier == \public() };
	
	// Select methods...
	mainMethods = { method | <method,typeSymbol> <- model.types, method in mainMethods
		&& typeSymbol.returnType == TypeSymbol::\void() // ...that have no return type (i.e. are void)
		&& size(typeSymbol.parameters) == 1 // ... take exactly 1 parameter 
		&& typeSymbol.parameters[0] == TypeSymbol::\array(TypeSymbol::\class(|java+class:///java/lang/String|, []), 1) // ...that is of type String[]. 
		};
	
	return mainMethods;
}



public set[loc] allocatedTypesIn(loc method, M3 model) 
{
	invokedConstructors = { c | <m,c> <- model.methodInvocation, m == method && isConstructor(c) };
	
	return { classOf(constructor, model) | constructor <- invokedConstructors };
}


public set[loc] allocatedTypesIn(set[loc] methods, M3 model) 
{
	invokedConstructors = { c | <m,c> <- model.methodInvocation, m in methods && isConstructor(c) };
	
	return { classOf(constructor, model) | constructor <- invokedConstructors };
}

public set[loc] superTypesOf(set[loc] classes, M3 model) 
{
	classSet = getDeclaredTypeHierarchy(model);
	
	// The transitive closure of classSet will give us all the direct and indirect
	// inheritance paths of each class.
	
	return { y | <x,y> <- classSet+, x in classes };
}




public set[loc] methodsOf(set[loc] classes, M3 model)
{
	return { y | <x,y> <- model.containment, x in classes && y.scheme == "java+method" };
}

data MethodSignature = methodSignature(str name, list[TypeSymbol] typeParameters, TypeSymbol returnType, list[TypeSymbol] parameters)
	| constructorSignature(str name, list[TypeSymbol] parameters);


public MethodSignature signatureOf(loc method, M3 model) 
{
	 list[TypeSymbol] typeSymbols = [ ts | <m,ts> <- model.types, m == method ];
	 
	 if(size(typeSymbols) == 1) 
	 {
		 str name = [ name | <name, m> <- model.names, m == method ][0];
		 
		 if(isConstructor(method)) {
		 	return constructorSignature(name, typeSymbols[0].parameters);
		 } 
		 else {
		 	return methodSignature(name, typeSymbols[0].typeParameters, typeSymbols[0].returnType, typeSymbols[0].parameters);
		 }
	 } 
	 else  
	 {
	 	throw "Cannot determine signature of <method>.";
	 } 
}


public bool identicalSignature(loc method1, loc method2, M3 model) 
{
	return signatureOf(method1, model) == signatureOf(method2, model);
}

