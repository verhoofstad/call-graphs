module main::Main

import Prelude;
import lang::java::m3::Core;
import lang::java::m3::AST;
import lang::java::jdt::m3::Core;

import main::DataSet;
import main::ReachabilityAnalysis;
import main::cha::ClassHierarchyAnalysis;

public void runAnalysis()
{
	M3 model = createM3FromEclipseProject(|project://TestCases|);
	
	rel[loc,loc] raGraph = runRaAnalysis(model);
	rel[loc,loc] chaGraph = runChaAnalysis(model);
	rel[loc,loc] rtaGraph = runRtaAnalysis(model);


	printReport(raGraph);
	printReport(chaGraph);
}

public void printReport(rel[loc,loc] callGraph)
{
	println("Nr of nodes: <size(carrier(callGraph))>");
	println("Nr of edges: <size(callGraph)>");
	
	//println("<callGraph>");
}


public void testJars() 
{
	for(jar <- jarFiles) 
	{
		println("Processing <jar>");
		startTime = now();
		model = createM3FromJar(jar);
		endTime = now();
		runningTime = endTime - startTime;
		println("Declarations: <size(model@declarations)>, duration <runningTime[3]>:<runningTime[4]>:<runningTime[5]>");
	}
}


