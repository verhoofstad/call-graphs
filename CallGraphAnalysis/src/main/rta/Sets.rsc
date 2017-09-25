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

// The set of all (anonymous) classes and interfaces.
// David Bacon refers to interfaces as interface classes (e.g. RTA TR, page 21)
public set[loc] Classes = {};

// The set of classes that can be instianted by a client in library scenario's.
public set[loc] ExportedClasses = {};

// The set of classes that can be inherited by a client in library scenario's).
public set[loc] DerivableClasses = {};

// The set of derivation edges.
public rel[loc base, loc derived] Derivations = {};

// The set of all methods, both interface and concrete methods.
// For now, we consider static methods and construtors as non-methods, thus not elements of this set. 
public set[loc] Methods = {};

// The set of public methods of the exported classes (for library scenario's).
public set[loc] PublicMethodsOfExportedClasses = {};

// The set of protected methods of the derivable classes (for library scenario's).
public set[loc] ProtectedMethodsOfDerivableClasses = {};

// The set of all functions defined by the program, both methods and non-methods.
// F does not include interfaces, only functions and methods that have code bodies. Therefore, MD is a subset F.
public set[loc] Functions = {};

// The set of exported functions in the library.
public set[loc] ExportedFunctions = {};

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
	if(model.id.scheme == "project") 
	{
		model = addDefaultConstructors(model);
		model = addConstructorsForAnonymousClasses(model);
	}

	Classes = classes(model) + interfaces(model);
	ExportedClasses = { class | class <- Classes, <class,\public()> in model.modifiers };
	DerivableClasses = { class | class <- ExportedClasses, <class,\final()> notin model.modifiers };

	Derivations = invert(getDeclaredTypeHierarchy(model));

	Methods = { method | method <- model.declarations, method.scheme == "java+method" && <method,\static()> notin model.modifiers };
	PublicMethodsOfExportedClasses = { <class,method> | <class,method> <- model.containment, class in ExportedClasses && <method,\public()> in model.modifiers };
	ProtectedMethodsOfDerivableClasses = { <class,method> | <class,method> <- model.containment, class in DerivableClasses && <method,\protected()> in model.modifiers };
	
	interfaceMethods = { method | <interface,method> <- model@containment, isInterface(interface) };
	
	Functions = { f | f <- model.declarations, (f.scheme == "java+method" || f.scheme == "java+constructor")
		&& <f,\abstract()> notin model.modifiers 
		&& f notin interfaceMethods };
		
	ExportedFunctions = { f | f <- Functions, <f,\public()> in model.modifiers };
	
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
	
	for(<method,target> <- model.methodInvocation) 
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



