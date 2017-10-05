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
        for(<b,c> <- derivations) 
        {
            // For each non-private method of 'b'.
            for(<b,m,d> <- visibleMethods, !isPrivate(m, model))
            {
                // If 'c' and 'd' both contain a method with the same signature it indicates 'c' already
                // inherited 'm' from another class 'e' (or in Java's case, another interface since it doesn's support multiple inheritance)
                // Based on the topological order of 'd' and 'e' it is determined which method takes precedence.
                if(any(<c,n,e> <- visibleMethods && identicalSignature(m, n, model))) 
                {
                    if(indexOf(topologicalOrder, d) > indexOf(topologicalOrder, e)) 
                    {
                        visibleMethods -= <c, n, e>; 
                        visibleMethods += <c, m, d>; 
                    }
                }
                else
                {
                    // Method 'm' is inherited by 'c' from superclass 'd'.
                    visibleMethods += <c, m, d>; 
                }
            }
        }
    }
    return <classes, derivations, visibleMethods>;
} 
