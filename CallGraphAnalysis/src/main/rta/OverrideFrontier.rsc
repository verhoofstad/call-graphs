module main::rta::OverrideFrontier

import Prelude;
import lang::java::m3::Core;
import lang::java::m3::AST;
import lang::java::m3::TypeHierarchy;
import lang::java::jdt::m3::Core;
import analysis::graphs::Graph;

import main::Util;
import main::rta::Sets;
import main::rta::ClassHierarchyGraph;


// Contains per visible method the set of Visible Methods that override 'v'. 
public map[VisibleMethod, set[VisibleMethod]] Override = ();

// Contains per visible method the set of Classes that inherit 'v'. (cone set)
public map[VisibleMethod, set[loc]] Inherit = ();


public void buildFrontier(M3 model) 
{
	CHG chg = buildCHG(model);

	buildFrontier(chg, model);	
}


public void buildFrontier(CHG chg, M3 model) 
{
	buildFrontier(chg.classes, chg.derivations, chg.visibleMethods, model);
}


public void buildFrontier(set[loc] classes, rel[loc,loc] derivations, set[VisibleMethod] visibleMethods, M3 model) 
{
	// Contains per visible method the set of visible methods that override 'v'. 
	Override = ();
	// Contains per visible method the set of classes that inherit 'v'. (cone set)
	Inherit = ();
	 
	map[VisibleMethod, set[VisibleMethod]] antiset = (); 

	for(visibleMethod <- visibleMethods) 
	{
		Override[visibleMethod] = {};
		Inherit[visibleMethod] = { visibleMethod.class };
		antiset[visibleMethod] = {};	
	}

	// Reversed topological order
	// We start at the leaf nodes and work aour way up.
	list[loc] reversedTopologicalOrder = reverse(order(derivations));
	
	for(c <- reversedTopologicalOrder) 
	{
		// For each visible method of 'c'.
		for(<m,d> <- [ <method,derived> | <base,method,derived> <- visibleMethods, base == c])
		{
			VisibleMethod v = <c,m,d>;
			
			// For each parent class of 'c'.
			for(b <- [ base | <base,derived> <- derivations, derived == c ]) 
			{
				
				list[tuple[loc method,loc derived]] identicalMethods = [ <method,derived> | <base,method,derived> <- visibleMethods, base == b && identicalSignature(m, method, model) ]; 
			
				if(size(identicalMethods) > 0) 
				{
					n = identicalMethods[0].method;
					e = identicalMethods[0].derived;
				
					VisibleMethod w = <b,n,e>;
					if(d == e) 
					{
						Inherit[w] += Inherit[v];
						Override[w] += Override[v];
					}
					else
					{
						Override[w] += { v };
						if(c != d) 
						{
							for(p <- [ base | <base,derived> <- derivations, derived == c && <base,m,d> in visibleMethods ]) 
							{
								antiset[<p,m,d>] += { v };
							}
						} 
					}
					antiset[w] += antiset[v];
					q = Override[w] & antiset[w];
					Override[w] = Override[w] - q;
					antiset[w] = antiset[w] - q;
				}
			}
		}
	}
}