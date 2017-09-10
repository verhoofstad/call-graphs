module main::RapidTypeAnalysis

import Prelude;
import lang::java::m3::Core;
import lang::java::m3::AST;
import lang::java::jdt::m3::Core;

import main::cha::ClassHierarchyAnalysis;
import main::Util;

public rel[loc,loc] runRtaAnalysis(loc project)
{
	return runRtaAnalysis(createM3FromEclipseProject(project));
}

public rel[loc,loc] runRtaAnalysis(M3 model)
{
	return runRtaAnalysis(model, runChaAnalysis(model));
}


public rel[loc,loc] runRtaAnalysis(M3 model, rel[loc,loc] chaGraph) 
{
	rel[loc,loc] rtaGraph = {};
	list[loc] worklist = [ method | method <- findMainMethods(model) ];

	if(size(worklist) > 1) 
	{
		println("Warning: ");
	}

	println("Worklist contains <size(worklist)> items.");
	
	// Create a list of all the static methods in the program
	// Note that this set does not contain Java's default constructors.
	set[loc] staticMethods = getStaticMethodsAndConstructors(model);
	
	while(!isEmpty(worklist))
	{
		// M = next method in W
		loc method = head(worklist);
		worklist = drop(1, worklist);
		
		// T = set of allocated types in M
		allocatedTypes = allocatedTypesIn(method, model);

		// T = T union allocated types in RTA callers of M
		// Nog uit te zoeken: Zijn de callers van M alleen de directe 
		// aanroepende methodes of ook de aanroepers daarvan?
		methodCallers = { caller | <caller,callee> <- rtaGraph, callee == method };
		allocatedTypes = allocatedTypes + allocatedTypesIn(methodCallers, model);

		allocatedTypes = allocatedTypes + superTypesOf(allocatedTypes, model);

		for(callsite <- getCallSites(method, model)) 
		{
			if(isStatic(callsite, model) || isConstructor(callsite)) 
			{
				rtaGraph += <method,callsite>;

				worklist = worklist + callsite;
			}
			else
			{
				// methods called from M in CHA
				chaMethods = { callee | <callsite2, callee> <- chaGraph, callsite2 == method };
				// M’ = M’ intersection methods declared in T or supertypes of T
				reachableMethods = chaMethods & methodsOf(allocatedTypes, model);

				// Add an edge from the method M to each method in M’
				for(reachableMethod <- reachableMethods) 
				{
					rtaGraph += <method, reachableMethod>;
				}				
         		// Add each method in M’ to W
				worklist = worklist + [ x | x <- reachableMethods ];
			}		
		}
		
	}
	return rtaGraph;
}

/*

RTA = call graph of only methods (no edges)
CHA = class hierachy analysis call graph
W = worklist containing the main method

while W is not empty
   M = next method in W
   T = set of allocated types in M
   T = T union allocated types in RTA callers of M
   for each callsite (C) in M
      if C is a static dispatch
         add an edge to the statically resolved method
      otherwise
         M’ = methods called from M in CHA
         M’ = M’ intersection methods declared in T or supertypes of T
         Add an edge from the method M to each method in M’
         Add each method in M’ to W
*/