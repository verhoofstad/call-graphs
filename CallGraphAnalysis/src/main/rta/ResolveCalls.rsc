module main::rta::ResolveCalls

import Prelude;

import lang::java::m3::Core;
import lang::java::m3::AST;
import lang::java::m3::TypeHierarchy;
import lang::java::jdt::m3::Core;

import main::Util;
import main::rta::Sets;
import main::rta::ProgramVirtualCallGraph;
import main::RapidTypeAnalysis;

public set[int] ResolvedCallSites = {};
public set[CallInstanceEdge] ResolvedCallInstances = {};


public void resolveCalls(set[loc] functions, set[int] liveCallSites, set[CallInstanceEdge] liveCallInstances) 
{	
	ResolvedCallSites = {};
	ResolvedCallInstances = {};
	
	for(s <- liveCallSites, s notin DirectCallSiteIds) 
	{
		Q = { <s,f,t,P> | <s,f,t,P> <- liveCallInstances };
	
		if(size(Q) == 1) 
		{
			ResolvedCallSites += s;
			ResolvedCallInstances += Q;
		}
	}
}


/*
*   Some try-out
*/
public rel[loc,loc] resolve(set[CallInstanceEdge] liveCallInstances, set[loc] liveClasses) 
{
	rel[loc,loc] directCalls = { <f,t> | <s,f,t,P> <- liveCallInstances, isEmpty(P) };

	rel[loc,loc] virtualCalls = { <f,t> | <s,f,t,P> <- liveCallInstances, !isEmpty(P & liveClasses) };
	
	return directCalls + virtualCalls;
}

