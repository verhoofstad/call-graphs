module main::rta::RapidTypeAnalysis


import Prelude;
import lang::java::m3::Core;
import lang::java::m3::AST;
import lang::java::m3::TypeHierarchy;
import lang::java::jdt::m3::Core;
import analysis::graphs::Graph;

import main::Util;
import main::rta::Sets;
import main::rta::ClassHierarchyGraph;
import main::rta::OverrideFrontier;
import main::rta::ProgramVirtualCallGraph;


// Some global variables;

// The set of instantiated classes. 
// If a class is instanmtiated it is added to this set but not iets superclasses.
public set[loc] LiveClasses = {};
public set[loc] LiveFunctions = {};
public set[int] LiveCallSites = {};
public set[CallInstanceEdge] LiveCallInstances = {};

// Mapping from classes to call instances.
public set[tuple[loc class, CallInstanceEdge callInstance]] Qv ={}; 



public void runRta(M3 model) 
{	
	initializeSets(model);
	
	CHG chg = buildCHG(Classes, Derivations, Methods, model);
	
	buildFrontier(chg, model);
	
	pvg = buildPVG(DirectCallSites, VirtualCallSites);
	
	rapidTypeAnalysis(pvg, model);
}



public void rapidTypeAnalysis(PVG pvg, M3 model) 
{
	// As an adaptation of RTA to handle Java the default Object class is added to the set of live classes.
	LiveClasses = { JavaObjectClass };
	LiveFunctions = {};
	LiveCallSites = {};
	LiveCallInstances = {};

	Qv = {};
	
	for(f <- pvg.rootFunctions)
	{
		println("Processing root function <f>");
		analyze(f, false, model);
	}
}


private void analyze(loc f, bool isBase, M3 model) 
{
	if(isConstructor(f) && !isBase) 
	{
		println("Instantiating class <classOf(f, model)> for function <f>.");
		instantiate(classOf(f, model), model);
	}
	
	if(f in LiveFunctions) 
	{
		return;
	}
	println("Adding <f> to LiveFunctions.");
	LiveFunctions += f;
	
	for( i <- [ callInstance | callInstance <- CallInstances, callInstance.callingFunction == f ])
	{
		// Direct calls are always added to the live call graph; 
		// virtual calls are only added if one of the possible classes for
		// the method is in the set of live classes CL (lines 14 and 15).
		if(i.callSiteId in DirectCallSiteIds || (i.callSiteId in VirtualCallSiteIds && !isEmpty(LiveClasses & i.possibleClasses))) 
		{
			addCall(i, model);
		}
		else
		{
			addVirtualMappings(i.possibleClasses, i);
		}
	} 
} 

private void addCall(CallInstanceEdge i, M3 model) 
{
	LiveCallInstances += i;
	LiveCallSites += i.callSiteId;

	analyze(i.targetFunction, isBaseConstructorCall(i), model);
}

private void instantiate(loc c, M3 model) 
{
	if(c in LiveClasses) 
	{
		return;
	}
	LiveClasses += c;
	
	for(i <- [ callInstance | <class,callInstance> <- Qv, class == c ])
	{
		if(i notin LiveCallInstances)
		{
			addCall(i, model);
			Qv = Qv - <c,i>;
		}
	}
}



public void addVirtualMappings(set[loc] possibleClasses, CallInstanceEdge i) 
{
	for(p <- possibleClasses) 
	{
		Qv += <p,i>;
	}
}



private bool isBaseConstructorCall(CallInstanceEdge i)
{
	// If the target function is a constructor and the calling function is also 
	// a constructor, we'll assume its a base constructor call.
	return isConstructor(i.callingFunction) && isConstructor(i.targetFunction);
}




