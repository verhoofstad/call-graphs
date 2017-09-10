module main::M3Extensions

import Prelude;
import lang::java::m3::Core;
import lang::java::m3::AST;
import lang::java::jdt::m3::Core;
import lang::java::m3::TypeHierarchy;
import lang::java::m3::TypeSymbol;

import analysis::m3::Core;


/*
	
	* If a class dos not inherit from another class, it implicitly inherits from java.lang.Object.

	* If a class has not constructor a parameterless default constructor is implicitly defined.

		- If a class contains no constructor declarations, then a default constructor with no formal parameters and no throws clause is 
		  implicitly declared.
		- If the class being declared is the primordial class Object, then the default constructor has an empty body. 
		  Otherwise, the default constructor simply invokes the superclass constructor with no arguments.
		- It is a compile-time error if a default constructor is implicitly declared but the superclass does not have 
		  an accessible constructor that takes no arguments and has no throws clause.
		- In a class type, if the class is declared public, then the default constructor is implicitly given the access modifier public; 
		  if the class is declared protected, then the default constructor is implicitly given the access modifier protected (§6.6);
		  if the class is declared private, then the default constructor is implicitly given the access modifier private (§6.6);
		  otherwise, the default constructor has the default access implied by no access modifier. 
	
		http://docs.oracle.com/javase/specs/jls/se7/html/jls-8.html#jls-8.8.9
	
	* If a class has no access modifier, it is implicitly package-private.
	
*/


public void m3PreChecks(M3 model) 
{
	// No anonymous class should have a constructor defined in either @declarations or @containtment.
}


/*
*  Ensures all classes and interface with no declared parent, inherit from java.lang.Object.
*/
public M3 addObjectInheritance(M3 model) 
{
}

public M3 addDefaultConstructors(M3 model) 
{
	classesWithoutConstructor = classes(model) - { class | <class,constructor> <- model@containment, isConstructor(constructor) };
		
	for(class <- classesWithoutConstructor) 
	{
		defaultConstructor = makeConstructorLocation(class);
	
		model@containment += <class, defaultConstructor>;
		model@names += <class.file, defaultConstructor>;
		model@types += <defaultConstructor, constructor(defaultConstructor, [])>;
		
		// Determine the access modifiers of the class. We're not interested if the class 
		// is abstract or final since it has no impact on the modifiers for the constructor. 
		modifiers = { m | <c,m> <- model@modifiers, c == class && m notin { \abstract(), \final() } };
		
		for(modifier <- modifiers) 
		{
			model@modifiers += <defaultConstructor, modifier>;
		}
		
		// Determine if the class has a parent class. If so, we add a method invocation from
		// the current class' constructor to the parent class' constructor.
		superClasses = [ superClass | <subClass, superClass> <- model@extends, subClass == class ];
		
		if(size(superClasses) == 1) 
		{
			model@methodInvocation += <defaultConstructor, makeConstructorLocation(superClasses[0])>;
		}
		elseif(size(superClasses) > 1) 
		{
			throw "Class <class> has more than one superclass. <superClasses>";
		}
	}		
	return model;
}

private loc makeConstructorLocation(loc class) 
{
	if(class.scheme != "java+class") throw "Only non-anonymous classes are supported.";

	return |java+constructor:///| + class.path + (class.file + "()");
}



// Becasue addConstructorsForAnonymousClasses is dependent on the constructor of 'normal' classes,
// the function addDefaultConstructors(M3) should have run prior to this function.

public M3 addConstructorsForAnonymousClasses(M3 model) 
{
	// An anonymous class cannot have an explicitly declared constructor.
	// So we can assume none of the anonymous classes have a constructor defined in the M3 model.
	classesWithoutConstructor = { c | <c,f> <- model@declarations, c.scheme == "java+anonymousClass" };
		
	for(anonymousClass <- classesWithoutConstructor) 
	{
		// An anonymous class always extends an existing class -or- implements an inteface.
		superTypes = [ superType | <subType, superType> <- model@extends + model@implements, subType == anonymousClass ];
		
		if(size(superTypes) != 1) 
		{
			throw "Anonymous class <anonymousClass> should have exactly 1 super type. <superTypes>";
		}

		// The super type of the anonymous class. It is either a class or an interface.
		superType = superTypes[0];		
	
		// Attempt to find the constructor invocation of the anonymous class. There should be exactly one.
		anonymousConstructors = [ t | <s,t> <- model@methodInvocation, contains(t.path, anonymousClass.path) ];
		
		if(size(anonymousConstructors) != 1) 
		{
			throw "Anonymous class <anonymousClass> should have exactly 1 constructor invocation. Actual: <size(anonymousConstructors)>\n<anonymousConstructors>";
		}
	
		anonymousConstructor = anonymousConstructors[0];
		str params = substring(anonymousConstructor.file, findLast(anonymousConstructor.file, "("));
	
	
		model@containment += <anonymousClass, anonymousConstructor>;

		if(isClass(superType)) 
		{
			// Attempt to find the constructor of the super class. Because there can be more than one
			// we include the parameter signature.
			parentConstructors = [ <con1,ts> | <class1,con1,con2,ts> <- model@containment join model@types, 
				con1 == con2 && isConstructor(con1) && class1 == superType && contains(con1.path, params) ];
			
			if(size(parentConstructors) != 1) 
			{
				throw "More than one parent constructor <parentConstructors>";
			}

			parentConstructor = parentConstructors[0][0];
			parentConstructorType = parentConstructors[0][1];
			
			model@methodInvocation += <anonymousConstructor, parentConstructor>;
			model@types += <anonymousConstructor, constructor(anonymousConstructor, parentConstructorType.parameters)>;
		}
		else
		{
			model@types += <anonymousConstructor, constructor(anonymousConstructor, [])>;
		}
	}		
	return model;
}