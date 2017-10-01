module main::rta::Util

import Prelude;
import lang::java::m3::Core;
import analysis::graphs::Graph;

import main::rta::Sets;
import main::rta::ClassHierarchyGraph;
import main::rta::OverrideFrontier;
import main::rta::ProgramVirtualCallGraph;
import main::rta::RapidTypeAnalysis;
import main::rta::ResolveCalls;




public rel[loc,loc] runRta(M3 model, bool forLibraries) 
{	
	initializeSets(model);
	
	CHG chg = buildCHG(Classes, Derivations, Methods, model);
	
	buildFrontier(chg, model);
	
	pvg = buildPVG(DirectCallSites, VirtualCallSites);
	
	rapidTypeAnalysis(pvg, model);

	rel[loc,loc] graph = resolve(LiveCallInstances, LiveClasses);
	return graph;
}

public CHG buildCHG(model) 
{
	initializeSets(model);
	
	return buildCHG(Classes, Derivations, Methods, model);
}

public void buildFrontier(M3 model) 
{
	CHG chg = buildCHG(model);

	buildFrontier(chg, model);	
}


public void buildFrontier(CHG chg, M3 model) 
{
	buildFrontier(chg.classes, chg.derivations, chg.visibleMethods, model);
}

public void printCHG(CHG chg) 
{
	println("Classes:");
	for(class <- sort(chg.classes)) 
	{
		println("   <class>");
	}
	
	println("Derivations:");
	for(derivation <- sort(chg.derivations)) 
	{
		println("   <derivation[0].path> :: <derivation[1].path>");
	}
	
	println("Visibe Methods:");
	for(visibleMethod <- sort(chg.visibleMethods)) 
	{
		print("   "); 
		printVisibleMethod(visibleMethod);
	}
}

public void printVisibleMethod(VisibleMethod visibleMethod) 
{
	println("{<visibleMethod.class.path>, <visibleMethod.method.path>, <visibleMethod.definingClass.path>}");
}

public void printInherit(map[VisibleMethod, set[loc]] inherit) 
{
	println("Inherit:");
	
	for(VisibleMethod key <- inherit) 
	{
		print("   ");
		printVisibleMethod(key);
		
		for(inherits <- inherit[key]) 
		{
			print("      ");
			println("<inherits>");
		}
	}	
}

public void printOverride(map[VisibleMethod, set[VisibleMethod]] override) 
{
}

public void printPVG(PVG pvg) 
{
	//tuple[set[loc] functions, set[int] callSiteIds, set[CallInstanceEdge] callInstances, set[loc] rootFunctions];
	
	println("Functions:");
	for(function <- sort(pvg.functions)) 
	{
		println("   <function>");
	}
	
	println("Call Sites:");
	println("   <sort(pvg.callSiteIds)>");
	
	println("Call Instance Edges:");
	for(callInstance <- sort(pvg.callInstances)) 
	{
		print("   ");
		printCallInstanceEdge(callInstance);
	}

	println("Root Functions:");
	for(function <- sort(pvg.rootFunctions)) 
	{
		println("   <function.path>");
	}
}

//CallInstanceEdge = tuple[int callSiteId, loc callingFunction, loc targetFunction, set[loc] possibleClasses];
public void printCallInstanceEdge(CallInstanceEdge callInstanceEdge) 
{
	println("{<callInstanceEdge.callSiteId>, <callInstanceEdge.callingFunction.path>, <callInstanceEdge.targetFunction.path>}");
	
	for(targetClass <- sort(callInstanceEdge.possibleClasses)) {
		println("      <targetClass.path>");
	}
} 
