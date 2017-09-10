module \test::UtilTest

import Prelude;
import lang::java::m3::Core;
import lang::java::m3::AST;
import lang::java::jdt::m3::Core;

import analysis::m3::Core;

import main::Util;

M3 testCases = createM3FromEclipseProject(|project://TestCases|);

test bool classOf_Ok() 
{
	// Arrange
	loc method = |java+method:///A/b()|;
	
	// Act
	loc result = classOf(method, testCases);
	
	assert result == |java+class:///A| : "Should be <|java+class://A|> but was <result>";
	return true; 
}



test bool isPrivate() 
{
	// Arrange
	loc publicMethod = |java+method:///isPrivate/SomeClass/publicMethod()|;
	loc protectedMethod = |java+method:///isPrivate/SomeClass/protectedMethod()|;
	loc privateMethod = |java+method:///isPrivate/SomeClass/privateMethod()|;
	
	// Act
	assert isPrivate(publicMethod, testCases) == false : "Method <publicMethod> should yield to false but didn\'t.";
	assert isPrivate(protectedMethod, testCases) == false : "Method <protectedMethod> should yield to false but didn\'t.";
	assert isPrivate(privateMethod, testCases) == true : "Method <privateMethod> should yield to true but didn\'t.";

	return true;
}


test bool signatureOf() 
{
	loc interfaceMethod1 = |java+method:///identicalSignature/SomeInterface/DoSomething()|;
	loc interfaceMethod2 = |java+method:///identicalSignature/SomeInterface/ReturnSomething()|;
	loc interfaceMethod3 = |java+method:///identicalSignature/SomeInterface/ReturnSomething(java.lang.String)|;

	loc constructor1 = |java+constructor:///identicalSignature/OtherClass/OtherClass()|;
	loc constructor2 = |java+constructor:///identicalSignature/SomeClass/SomeClass()|;

	loc someClassMethod1 = |java+method:///identicalSignature/SomeClass/DoSomething()|;
	loc someClassMethod2 = |java+method:///identicalSignature/SomeClass/ReturnSomething()|;
	loc someClassMethod3 = |java+method:///identicalSignature/SomeClass/ReturnSomething(java.lang.String)|;

	loc otherClass1 = |java+method:///identicalSignature/OtherClass/DoSomething()|;
	loc otherClass2 = |java+method:///identicalSignature/OtherClass/ReturnSomething()|;
	loc otherClass3 = |java+method:///identicalSignature/OtherClass/ReturnSomething(java.lang.String)|;

	assert identicalSignature(interfaceMethod1, someClassMethod1, testCases) == true : "Method <interfaceMethod1> and <someClassMethod1> should yield to true but didn\'t.";
	assert identicalSignature(interfaceMethod2, someClassMethod2, testCases) == true : "Method <interfaceMethod2> and <someClassMethod2> should yield to true but didn\'t.";
	assert identicalSignature(interfaceMethod3, someClassMethod3, testCases) == true : "Method <interfaceMethod3> and <someClassMethod3> should yield to true but didn\'t.";



	assert identicalSignature(constructor1, constructor2, testCases) == false : "Method <constructor1> and <constructor2> should yield to true but didn\'t.";
	assert identicalSignature(constructor1, constructor1, testCases) == false : "Method <constructor1> and <constructor2> should yield to true but didn\'t.";

	return true;
}
