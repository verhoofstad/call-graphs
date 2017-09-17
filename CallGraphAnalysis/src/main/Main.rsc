module main::Main

import Prelude;
import List;
import lang::java::m3::Core;
import lang::java::m3::AST;
import lang::java::jdt::m3::Core;

import main::DataSet;
import main::ReachabilityAnalysis;
import main::cha::ClassHierarchyAnalysis;

import main::results::ResultSet;
import main::results::LoadResults;

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
	startTime = now();
	int count = 0;

	println("Load results file");	
	results = LoadResults(resultsFile);
	
	//println("Load Java Libraries...");	
	//jreModel = Compose(javaLib);
	M3 jreModel = m3(|project:///empty|);

	for(dataset <- TestDataSet) 
	{
		resultSet = resultsOf(results, dataset.organisation,  dataset.name, dataset.revision);
	
		testJar(dataset, count, resultSet, jreModel);
		count += 1;
	}

	endTime = now();
	runningTime = endTime - startTime;
}

public void testJar(tuple[str organisation, str name, str revision, loc cpFile, list[loc] libFiles] dataset, int count, result resultSet, M3 jreModel) 
{
	println("Processing: <count> with <dataset.organisation> | <dataset.name> | <dataset.revision>");
	println("");
	println("CPFILE: <dataset.cpFile>");
	println("LibFiles: <dataset.libFiles[0]>");

	for(libFile <- tail(dataset.libFiles)) 
	{
		println("  <libFile>");
	}

	libStartTime = now();
	
	cpModel = createM3FromJar(dataset.cpFile);

	//libModel = Compose(toSet(dataset.libFiles));
	//libModel = composeM3(|project://merged|, { model, jreModel });
	M3 libModel = m3(|project:///empty|);
	
	compareM3(cpModel, libModel, resultSet);
	
	//validateM3(cpModel);

	libEndTime = now();
	libRunningTime = libEndTime - libStartTime;
	println("");
	
	//println("Declarations: <size(model.declarations)>, duration <libRunningTime[3]>:<libRunningTime[4]>:<libRunningTime[5]>");
	//println("Classes: <size(classes(model))>, Interfaces: <size(interfaces(model))>");
}


public M3 Compose(tuple[str organisation, str name, str revision, loc cpFile, list[loc] libFiles] dataset) 
{
	return Compose(dataset.cpFile, toSet(dataset.libFiles));
}

public M3 Compose(loc cpFile, set[loc] libFiles) 
{
	return Compose({cpFile} + libFiles - javaLibraries);
}

public M3 Compose(set[loc] jarFiles) 
{
	set[M3] models = {};
	
	for(jarFile <- jarFiles)
	{
		models += createM3FromJar(jarFile);
	}

	return composeM3(|project://merged|, models);	
}


public void compareM3(M3 cpModel, M3 libModel, result resultSet) 
{
	int project_classCount = size(classes(cpModel));
	int project_interfaceCount = size(interfaces(cpModel));
	int project_publicClassCount = size( { c | <c,m> <- cpModel.modifiers, isClass(c) && m == \public() } );
	int project_packageVisibleClassCount = project_classCount - project_publicClassCount;
	int project_publicInterfaceCount = size( { i | <i,m> <- cpModel.modifiers, isInterface(i) && m == \public() } );
	int project_packageVisibleInterfaceCount = project_interfaceCount - project_publicInterfaceCount;

	int project_methodCount = size(methods(cpModel));
	int project_publicMethods = size( { me | <me,m> <- cpModel.modifiers, isMethod(me) && m == \public() } );
	int project_protectedMethods = size( { me | <me,m> <- cpModel.modifiers, isMethod(me) && m == \protected() } );
	int project_privateMethods = size( { me | <me,m> <- cpModel.modifiers, isMethod(me) && m == \private() } );
	int project_packagePrivateMethods = project_methodCount - project_publicMethods - project_protectedMethods - project_privateMethods;


	println("");
	println("	Project class count:                     <project_classCount>, <resultSet.project_classCount>"); 
	println("	Project interface count:                 <project_interfaceCount>, <resultSet.project_interfaceCount>"); 
	println("	Project public class count:              <project_publicClassCount>, <resultSet.project_publicClassCount>"); 
	println("	Project package visible count:           <project_packageVisibleClassCount>, <resultSet.project_packageVisibleClassCount>"); 
	println("	Project public interface count:          <project_publicInterfaceCount>, <resultSet.project_publicInterfaceCount>"); 
	println("	Project package visible interface count: <project_packageVisibleInterfaceCount>, <resultSet.project_packageVisibleInterfaceCount>"); 
	println("	Project method count:                    <project_methodCount>, <resultSet.project_methodCount>"); 
	println("	Project public method count:             <project_publicMethods>, <resultSet.project_publicMethods>"); 
	println("	Project protected method count:          <project_protectedMethods>, <resultSet.project_protectedMethods>"); 
	println("	Project package private method count:    <project_packagePrivateMethods>, <resultSet.project_packagePrivateMethods>"); 
	println("	Project private method count:            <project_privateMethods>, <resultSet.project_privateMethods>"); 
	
	
	/*
	int all_classCount,
	int all_interfaceCount,
	int all_publicClassCount,
	int all_packageVisibleClassCount,
	int all_publicInterfaceCount,
	int all_packageVisibleInterfaceCount,
	int libraries_classFileCount,
	int libraries_classCount,
	int libraries_interfaceCount,
	int libraries_publicClassCount,
	int libraries_packageVisibleClassCount,
	int libraries_publicInterfaceCount,
	int libraries_packageVisibleInterfaceCount,
	int all_methodCount,
	int all_publicMethods,
	int all_protectedMethods,
	int all_packagePrivateMethods,
	int all_privateMethods,
	int libraries_methodCount,
	int libraries_publicMethods,
	int libraries_protectedMethods,
	int libraries_packagePrivateMethods,
	int libraries_privateMethods,
	*/
} 

public void validateM3(M3 model) 
{
	set[loc]  notDeclared = {};
	
	
	notDeclared = carrier(model.methodInvocation) - domain(model.declarations);
	println("Undeclared method invocations: <size(notDeclared)>");
	
	notDeclared = carrier(model.extends) - domain(model.declarations);
	println("Undeclared extends:            <size(notDeclared)>");

	notDeclared = carrier(model.implements) - domain(model.declarations);
	println("Undeclared implements:         <size(notDeclared)>");
 	
}


public void printM3(M3 model) 
{
	println("Statistics for <model.id>");
	println("");

	println("Number of declarations: <size(model.declarations)>");
	println("Number of method invocations: <size(model.methodInvocation)>");
	println("Number of unique methods in method invocations: <size(carrier(model.methodInvocation))>");
	println("Number of implements: <size(model.implements)>");
	println("Number of extends: <size(model.extends)>");
	println("Number of names: <size(model.names)>");
	println("Number of modifiers: <size(model.modifiers)>");
}

