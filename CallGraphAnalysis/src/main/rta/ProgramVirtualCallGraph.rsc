module main::rta::ProgramVirtualCallGraph

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

alias CallInstanceEdge = tuple[int callSiteId, loc callingFunction, loc targetFunction, set[loc] possibleClasses];

// I is the set of call instance edges, and
public set[CallInstanceEdge] CallInstances = {};

alias PVG = tuple[set[loc] functions, set[int] callSiteIds, set[CallInstanceEdge] callInstances, set[loc] rootFunctions];


public PVG buildPVG(M3 model) 
{
    if(isEmpty(DirectCallSites) && isEmpty(VirtualCallSites)) 
    {
        initializeSets(model);
    }
    
    if(isEmpty(Inherit) && isEmpty(Override)) 
    {
        buildFrontier(model);
    }
    return buildPVG(DirectCallSites, VirtualCallSites);
}

public PVG buildPVG(set[DirectCallSite] directCallSites, set[VirtualCallSite] virtualCallSites) 
{
    CallInstances = {};
    
    for(<s,f,g> <- directCallSites) 
    {
        CallInstances += {<s,f,g,{}>};
    }
    for(<s,f,v> <- virtualCallSites) 
    {
        addVirtualInstances(s, f, v);
    }
    return <Functions, CallSiteIds, CallInstances, RootFunctions>;
}


public void	addVirtualInstances(int virtualCallSiteId, loc callingFunction, VisibleMethod visibleMethod) 
{
    if(<virtualCallSiteId, callingFunction, visibleMethod.method, Inherit[visibleMethod]> in CallInstances) 
    {
        return;
    }
    
    CallInstances += <virtualCallSiteId, callingFunction, visibleMethod.method, Inherit[visibleMethod]>;
    
    for(w <- Override[visibleMethod]) 
    {
        addVirtualInstances(virtualCallSiteId, callingFunction, w);
    }
}