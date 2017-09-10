module main::rta::ResolveCalls

import Prelude;

import lang::java::m3::Core;
import lang::java::m3::AST;
import lang::java::m3::TypeHierarchy;
import lang::java::jdt::m3::Core;


import main::Util;
import main::rta::Sets;
import main::rta::ProgramVirtualCallGraph;
import main::rta::RapidTypeAnalysis;
import main::RapidTypeAnalysis;

public set[int] ResolvedCallSites = {};
public set[CallInstanceEdge] ResolvedCallInstances = {};


public void resolveCalls(set[loc] functions, set[int] liveCallSites, set[CallInstanceEdge] liveCallInstances) 
{	
	ResolvedCallSites = {};
	ResolvedCallInstances = {};
	
	for(callSiteId <- [ callSiteId | callSiteId <- liveCallSites, callSiteId notin DirectCallSiteIds ]) 
	{
		Q = { <s,f,t,P> | <s,f,t,P> <- liveCallInstances, s == callSiteId };
	
		if(size(Q) == 1) 
		{
			ResolvedCallSites += callSiteId;
			ResolvedCallInstances += Q;
		}
	}
}

public rel[loc,loc] resolve() 
{
	rel[loc,loc] directCalls = { <f,t> | <s,f,t,P> <- LiveCallInstances, isEmpty(P) };

	rel[loc,loc] virtualCalls = { <f,t> | <s,f,t,P> <- LiveCallInstances, !isEmpty(P & LiveClasses) };
	
	return directCalls + virtualCalls;
}


public tuple[lrel[loc,loc], lrel[loc,loc], lrel[loc,loc], lrel[loc,loc]] runAll() 
{
	model1 = createM3FromEclipseProject(|project://TestCases|);
	model2 = createM3FromEclipseProject(|project://RtaCase2|);
	
	rtaOld1 = sort(runRtaAnalysis(model1));
	
	runRta(model1);
	rtaNew1 = sort(resolve());


	rtaOld2 = sort(runRtaAnalysis(model2));
	
	runRta(model2);
	rtaNew2 = sort(resolve());
	
	return <rtaOld1, rtaNew1, rtaOld2, rtaNew2>;
}