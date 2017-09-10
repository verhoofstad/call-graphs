module \test::rta::SetsTest

import Prelude;
import lang::java::m3::Core;
import lang::java::m3::AST;
import lang::java::jdt::m3::Core;

import analysis::graphs::Graph;


//import lang::java::m3::TypeHierarchy;

import analysis::m3::Core;


import main::rta::Sets;


test bool initializeSets_ok() 
{
	M3 testCases = createM3FromEclipseProject(|project://TestCases|);

	initializeSets(testCases);
	
	
	// The set of classes.
	assert !isEmpty(Classes) : "The set Classes should not be empty.";
	assert Classes == { c | c <- Classes, isClass(c) || isInterface(c) } : "The set Classes should only contain (anonymous) classes or interfaces.";
	
	// Assert the set 'Derivations'.
	assert top(Derivations) == {|java+class:///java/lang/Object|} : "There should be only 1 base class in Derivations namely Object.";
	assert carrier(Derivations) <= Classes : "All classes and interfaces in Derivations should be an element of Classes.";
	 
	// Assert the sets 'CallSiteIds'.
	assert DirectCallSiteIds <= CallSiteIds : "DirectCallSiteIds should be a subset of CallSiteIds.";
	assert VirtualCallSiteIds <= CallSiteIds : "VirtualCallSiteIds should be a subset of CallSiteIds.";
	assert (DirectCallSiteIds + VirtualCallSiteIds) == CallSiteIds : "";
	assert isEmpty(DirectCallSiteIds & VirtualCallSiteIds) : "DirectCallSiteIds and VirtualCallSiteIds should not have shared elements.";


/*
// The set of all methods, both interface and concrete methods.
//public set[loc] Methods = {};

// The set of all functions defined by the program, both methods and non-methods.
// F does not include interfaces, only functions and methods that have code bodies. Therefore, MD is a subset F.
public set[loc] Functions = {};


public set[loc] RootFunctions = {};




public set[DirectCallSite] DirectCallSites = {};

// VirtualCallSites is a subset of CallSites
public set[VirtualCallSite] VirtualCallSites = {};
	
	*/

	return true;
}
