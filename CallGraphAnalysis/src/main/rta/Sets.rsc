module main::rta::Sets

import Prelude;
import lang::java::m3::Core;
import lang::java::m3::AST;
import lang::java::m3::TypeHierarchy;
import lang::java::jdt::m3::Core;

import main::M3Extensions;
import main::Util;

alias VisibleMethod = tuple[loc class, loc method, loc definingClass];

alias DirectCallSite = tuple[int callSiteId, loc callingFunction, loc targetFunction];
alias VirtualCallSite = tuple[int callSiteId, loc callingFunction, VisibleMethod visibleFunctions];

// The set of (anonymous) classes and interfaces.
public set[loc] Classes = {};

// The set of derivation edges.
public rel[loc base, loc derived] Derivations = {};

// The set of all methods, both interface and concrete methods.
public set[loc] Methods = {};

// The set of all functions defined by the program, both methods and non-methods.
// F does not include interfaces, only functions and methods that have code bodies. Therefore, MD is a subset F.
public set[loc] Functions = {};

// The set of root methods (usually the program's main function).
public set[loc] RootFunctions = {};

// S is the set of call site sub-nodes,
public set[int] CallSiteIds = {};

public set[int] DirectCallSiteIds = {};

// VirtualCallSites is a subset of CallSites
public set[int] VirtualCallSiteIds = {};


public set[DirectCallSite] DirectCallSites = {};

// VirtualCallSites is a subset of CallSites
public set[VirtualCallSite] VirtualCallSites = {};


public loc JavaObjectClass = |java+class:///java/lang/Object|;



public void initializeSets(M3 model) 
{
	model = addDefaultConstructors(model);

	Classes = classes(model) + interfaces(model);

	Derivations = invert(getDeclaredTypeHierarchy(model));

	Methods = methods(model);
	
	abstractMethods = { method | <method,modifier> <- model@modifiers, isMethod(method) && modifier == \abstract() };
	interfaceMethods = { method | <interface,method> <- model@containment, isInterface(interface) };
	
	Functions = { m | m <- Methods, m notin abstractMethods && m notin interfaceMethods };
	
	RootFunctions = findMainMethods(model);
	
	if(isEmpty(RootFunctions)) 
	{
		println("Warning: No root functions found.");
	}
	
	initializeCallSites(model);
}



private void initializeCallSites(M3 model) 
{
	int callSiteId = 1;
	
	DirectCallSites = {};
	VirtualCallSites = {};
	
	for(<method,target> <- model@methodInvocation) 
	{
		CallSiteIds += callSiteId;
		
		if(isStatic(target, model)) 
		{
			DirectCallSiteIds += callSiteId;
			DirectCallSites += <callSiteId, method, target>;
		} 
		else
		{
			loc targetClass = classOf(target, model);
		
			VirtualCallSiteIds += callSiteId;
			VirtualCallSites += <callSiteId, method, <targetClass, target, targetClass>>;
		}
		callSiteId += 1;
	}
}



