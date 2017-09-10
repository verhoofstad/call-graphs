module main::rta::ClassHierarchyGraph

import Prelude;
import lang::java::m3::Core;
import lang::java::m3::AST;
import lang::java::m3::TypeHierarchy;
import lang::java::jdt::m3::Core;
import analysis::graphs::Graph;

import main::Util;
import main::rta::Sets;


alias CHG = tuple[set[loc] classes, rel[loc,loc] derivations, set[VisibleMethod] visibleMethods];


public CHG buildCHG(M3 model) 
{
	if(isEmpty(Classes) && isEmpty(Derivations) && isEmpty(Methods)) 
	{
		println("Initializing sets...");
		initializeSets(model);
	}

	return buildCHG(Classes, Derivations, Methods, model);
}


public CHG buildCHG(set[loc] classes, rel[loc,loc] derivations, set[loc] methods, M3 model)
{
	set[VisibleMethod] visibleMethods = {};
	
	list[loc] topologicalOrder = order(derivations);
	
	for(method <- methods) 
	{
		visibleMethods += <classOf(method, model), method, classOf(method, model)>;
	}
	
	for(c <- topologicalOrder) 
	{
		// For each superclass of 'c'.
		for(b <- [ base | <base,derived> <- derivations, derived == c ]) 
		{
			// For each non-private method of 'b'.
			for(<m,d> <- [ <method,derived> | <base,method,derived> <- visibleMethods, base == b && !isPrivate(method, model) 
				//&& !isConstructor(method)	// Constructors cannot be inherited
			])
			{
				list[tuple[loc method,loc derived]] identicalMethods = [ <method,derived> | <base,method,derived> <- visibleMethods, base == c && identicalSignature(m, method, model) ]; 
			
				if(size(identicalMethods) > 0) 
				{
					loc n = identicalMethods[0].method;
					loc e = identicalMethods[0].derived;				
				
					if(indexOf(topologicalOrder, d) > indexOf(topologicalOrder, e)) 
					{
						visibleMethods -= <c, n, e>; 
						visibleMethods += <c, m, d>; 
					}
				} 
				else
				{
					visibleMethods += <c, m, d>; 
				}
			}
		}
	}
	return <classes, derivations, visibleMethods>;
} 
