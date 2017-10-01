module \test::M3ExtensionsTest

import Prelude;
import lang::java::m3::Core;
import lang::java::m3::AST;
import lang::java::jdt::m3::Core;

import analysis::m3::Core;

import main::M3Extensions;

M3 testCases = createM3FromEclipseProject(|project://TestCases|);

test bool addDefaultConstructors_Ok() 
{
	// Arrange
	loc class;
	loc defaultConstructor;

	// Act	
	M3 model = addDefaultConstructors(testCases);
	
	// Assert a default constructor has been added for SomeClass.
	class = |java+class:///m3Extensions/SomeClass|;
	defaultConstructor = |java+constructor:///m3Extensions/SomeClass/SomeClass()|;
	
	assert <class, defaultConstructor> in model.containment : "Constru";  
	assert <"SomeClass", defaultConstructor> in model.names : "";
	assert <defaultConstructor, constructor(defaultConstructor, [])> in model.types : "";
	assert <defaultConstructor, \public()> in model.modifiers : "The default constructor <defaultConstructor> should have a public modifier.";
	
	// Assert no default constructor has been added for WithParameterizedConstructor.
	class = |java+class:///m3Extensions/WithParameterizedConstructor|;
	defaultConstructor = |java+constructor:///m3Extensions/WithParameterizedConstructor/WithParameterizedConstructor()|;
	
	assert defaultConstructor notin range(model.containment) : "A default constructor should not be added for <class>.";  
	assert defaultConstructor notin range(model.names) : "A default constructor should not be added";
	assert defaultConstructor notin domain(model.types) : "";
	assert defaultConstructor notin domain(model.modifiers) : "The should be no modifier for <defaultConstructor>.";
	
	// Assert a default constructor is added for PackagePrivate and its modifier is package private.
	class = |java+class:///m3Extensions/PackagePrivate|;
	defaultConstructor = |java+constructor:///m3Extensions/PackagePrivate/PackagePrivate()|;
	
	assert <class, defaultConstructor> in model.containment : "Constru";  
	assert <"PackagePrivate", defaultConstructor> in model.names : "";
	assert <defaultConstructor, constructor(defaultConstructor, [])> in model.types : "";
	assert defaultConstructor notin domain(model.modifiers) : "The should be no modifier for <defaultConstructor> (package-private).";
	

	// Assert a default constructor has been added for SomeSubClass and it has a call to its parent constructor.
	class = |java+class:///m3Extensions/SomeSubClass|;
	defaultConstructor = |java+constructor:///m3Extensions/SomeSubClass/SomeSubClass()|;
	parentConstructor = |java+constructor:///m3Extensions/SomeClass/SomeClass()|;
	
	assert <class, defaultConstructor> in model.containment : "Constru";  
	assert <"SomeSubClass", defaultConstructor> in model.names : "";
	assert <defaultConstructor, constructor(defaultConstructor, [])> in model.types : "";
	assert <defaultConstructor, \public()> in model.modifiers : "The default constructor <defaultConstructor> should have a public modifier.";
	assert <defaultConstructor, parentConstructor> in model.methodInvocation
		 : "There should be a method invocation from <defaultConstructor> to <parentConstructor>."; 
		 
	return true;
}

test bool addConstructorsForAnonymousClasses_ok() 
{
	// Arrange
	loc anonymousClass, anonymousConstructor, parentConstructor;

	// Act	
	M3 model = addDefaultConstructors(testCases);
	
	model = addConstructorsForAnonymousClasses(model);

	// Assert a construtor has been added for an anonymous class.
	anonymousClass = |java+anonymousClass:///m3Extensions/SomeClass/SomeMethod()/$anonymous1|;
	anonymousConstructor = |java+constructor:///m3Extensions/SomeClass/SomeMethod()/$anonymous1/()|;
	parentConstructor = |java+constructor:///m3Extensions/SomeClass/SomeClass()|;

	assert <anonymousClass, anonymousConstructor> in model.containment : "Constru";  
	assert <anonymousConstructor, constructor(anonymousConstructor, [])> in model.types : "";
	assert <anonymousConstructor, parentConstructor> in model.methodInvocation
		: "There should be a method invocation from <anonymousConstructor> to <parentConstructor>."; 
		 

	// Assert 	
	anonymousClass = |java+anonymousClass:///m3Extensions/SomeClass/SomeMethod()/$anonymous2|;
	anonymousConstructor = |java+constructor:///m3Extensions/SomeClass/SomeMethod()/$anonymous2/()|;
	parentConstructor = |java+constructor:///m3Extensions/WithParameterizedConstructor/WithParameterizedConstructor()|;

	assert <anonymousClass, anonymousConstructor> in model.containment : "Constru";  
	assert <anonymousConstructor, constructor(anonymousConstructor, [])> in model.types : "";
	assert <anonymousConstructor, parentConstructor> in model.methodInvocation
		: "There should be a method invocation from <anonymousConstructor> to <parentConstructor>."; 

	// Assert 
	anonymousClass = |java+anonymousClass:///m3Extensions/SomeClass/SomeMethod()/$anonymous3|;
	anonymousConstructor = |java+constructor:///m3Extensions/SomeClass/SomeMethod()/$anonymous3/(java.lang.String)|;
	parentConstructor = |java+constructor:///m3Extensions/WithParameterizedConstructor/WithParameterizedConstructor(java.lang.String)|;
	
	assert <anonymousClass, anonymousConstructor> in model.containment : "Constru";  
	assert <anonymousConstructor, constructor(anonymousConstructor, [class(|java+class:///java/lang/String|,[])])> in model.types : "";
	assert <anonymousConstructor, parentConstructor> in model.methodInvocation
		: "There should be a method invocation from <anonymousConstructor> to <parentConstructor>."; 

 
 	// Assert there is no method invocation if the anonymous class implements an interface.
	anonymousClass = |java+anonymousClass:///m3Extensions/SomeClass/SomeMethod()/$anonymous4|;
	anonymousConstructor = |java+constructor:///m3Extensions/SomeClass/SomeMethod()/$anonymous4/()|;

	assert anonymousConstructor notin domain(model.methodInvocation) 
		: "There should be no method invocation from an anonymous constructor if it implements an interface.";
 	
 
	return true; 
}

