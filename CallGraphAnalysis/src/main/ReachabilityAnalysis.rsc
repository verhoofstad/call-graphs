module main::ReachabilityAnalysis

import Prelude;
import lang::java::m3::Core;
import lang::java::m3::AST;
import lang::java::jdt::m3::Core;

import main::Util;

public rel[loc,loc] runRaAnalysis(M3 model) 
{
	rel[loc,loc] edges = {};

	set[loc] staticMethods = getStaticMethodsAndConstructors(model);

	for(method <- methods(model)) {
		
		for(callsite <- getCallSites(method, model)) 
		{
			if(callsite in staticMethods) {
				
				edges += <method,callsite>;
					
			} else{
				str name = getMethodName(model, callsite);
				
				list[loc] rm = [ rm | <n,rm> <- model@names, n == name && rm.scheme == "java+method" ];
				
				for(reachableMethod <- rm) 
				{
					edges += <method, reachableMethod>;
				}
			}
		}	
	}
	return edges;
}