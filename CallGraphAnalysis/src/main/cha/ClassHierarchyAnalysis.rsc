module main::cha::ClassHierarchyAnalysis

import Prelude;
import lang::java::m3::Core;
import lang::java::m3::AST;
import lang::java::jdt::m3::Core;

import main::Util;


public rel[loc,loc] runChaAnalysis(M3 model) {

	rel[loc,loc] edges = {};

	// Create a list of all the static methods in the program
	// Note that this set does not contain Java's default constructors.
	set[loc] staticMethods = getStaticMethodsAndConstructors(model);

	for(method <- methods(model)) 
	{
		for(callsite <- getCallSites(method, model)) 
		{
println("Verwerken van callsite: <method> naar <callsite>");		
		
			if(isStatic(callsite, model) || isConstructor(callsite)) 
			{
				edges += <method,callsite>;
					
			} else{
	
				loc methodClass = classOf(method, model);
println("Klasse van aanroepende methode: <methodClass>");				
				// Get all methods that override the callsite.
				set[loc] overrides = { ov | <ov,b> <- model@methodOverrides, b == callsite };				
println("Overrides van <callsite>: <overrides>");	
				set[loc] cone = getConeClassSet(model, classOf(callsite, model));
println("Cone set van <callsite>: <cone>");				
				if(methodClass in cone) {
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

/*
public set[loc] getMethods(M3 model, set[loc] coneSet, loc method)
{
	str name = getMethodName(model, method);

	list[loc] others = [ method | <x, method> <- model@names, x == name && method.scheme == "java+method" ];
	
	set[loc] result = {};

	for(class <- coneSet) {
		
		set[loc] methods = { y | <x,y> <- model@containment, x == class && y.scheme == "java+method" };

		for(reachableMethod <- methods) 
		{
			str callSitename = getMethodName(model, reachableMethod);
			
			if(callSitename == name) {
				result += reachableMethod;
			}
		}		
	}
	return result;
}
*/
