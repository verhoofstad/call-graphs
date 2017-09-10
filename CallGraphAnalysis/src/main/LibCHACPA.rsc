module LibCHACPA

import Prelude;
import lang::java::m3::Core;
import lang::java::m3::AST;
import lang::java::jdt::m3::Core;

import Util;


public bool isEntryPoint(M3 model, loc method, loc declType) 
{
	return maybeCalledByTheJVM(model, method) || 
		(isStatic(model, method) && isAccessible(model, declType)) ||
		(isClientCallable(model, method) && ( isStatic(model, method) || isInstantiable(model, declType)));
}

public bool maybeCalledByTheJVM(M3 Model, loc method) 
{
	return true;
}


loc serializable = |java+interface:///java/io/Serializable|;
loc externalizable = |java+interface:///java/io/Externalizable|;


/*

The second test (Line 3) is extended
and now also tests if the static initializer’s declaring class
(declType) is accessible. The latter is the case if the class
or a subclass of it can be referenced from client code. In
general, a class is referenced whenever the name of the class
can appear in the code without violating visibility constraints.
Hence, all public classes and also all package private classes
that have a public subclass are immediately accessible.
*/
public bool isAccessible(M3 model, loc declType) 
{

}

public bool isClientCallable(M3 model, loc method, loc declType) 
{
	

	return (isPublic(method, model) || isProtected(method, model)
		&& (isPublic(declType, model) || false))
		
	;
	
}