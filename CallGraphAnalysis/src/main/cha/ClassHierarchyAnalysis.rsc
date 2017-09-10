module main::cha::ClassHierarchyAnalysis

import Prelude;
import lang::java::m3::Core;
import lang::java::m3::AST;
import lang::java::jdt::m3::Core;

import main::Util;


public rel[loc,loc] runChaAnalysis(M3 model) {

	rel[loc,loc] edges = {};

	for(method <- methods(model)) 
	{
		for(callsite <- getCallSites(method, model)) 
		{
			if(isStatic(callsite, model) || isConstructor(callsite)) 
			{
				edges += <method,callsite>;
			} 
			else
			{
				loc methodClass = classOf(method, model);
				// Get all methods that override the callsite.
				set[loc] overrides = { ov | <ov,b> <- model@methodOverrides, b == callsite };				
				set[loc] cone = getConeClassSet(model, classOf(callsite, model));

				if(methodClass in cone) 
				{
					// The call is made within the own class hierarchy (e.g. this or base)
					set[loc] methodCone = getConeClassSet(model, methodClass);

					edges += <method, callsite>;
					
					for(reachableMethod <- overrides) 
					{
						if(classOf(reachableMethod, model) in methodCone) {
							edges += <method, reachableMethod>;
						} 
					}					
				} 
				else 
				{
					edges += <method, callsite>;
				
					for(reachableMethod <- overrides) 
					{
						edges += <method, reachableMethod>;
					}
				}
			}
		}	
	}
	return edges;
}
