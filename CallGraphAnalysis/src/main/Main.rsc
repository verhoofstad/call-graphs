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


// Environmental settings
public loc libraryFolder = |file:///C:/CallGraphData/Libraries|;
public loc jdkFolder = |file:///C:/CallGraphData/JavaJDK/java-8-openjdk-amd64|;
public loc resultsFile = |file:///C:/CallGraphData/results.txt|;
public loc differencesFile = |file:///C:/CallGraphData/differences.txt|;


public void analyseJars() 
{
	analyseJars([0..99]);
}


public void analyseJars(list[int] libraryIdentifiers) 
{
	startTime = now();

	print("Loading results file...");	
	results = LoadResults(resultsFile);
	println("Ok");
	
	print("Loading Java JDK Libraries...");	
	jdkModel = createM3FromLocation(jdkFolder);
	println("Ok");
	println();

	list[str] differences = [];

	for(library <- TestDataSet, library.id in libraryIdentifiers) 
	{
		resultSet = resultsOf(results, library.organisation,  library.name, library.revision);
	
		differences = differences + analyseJar(library, resultSet, jdkModel);
	}

	runningTime = now() - startTime;
	
	writeFile(differencesFile, "Generated on <now()>\r\n");
	
	for(line <- differences) 
	{
		appendToFile(differencesFile, line + "\r\n");
	}
	
	println("");
	println("Total running time: <formatDuration(runningTime)>");
}

public list[str] analyseJar(Library library, result resultSet, M3 jdkModel) 
{
	println("Processing: <library.id> with <library.organisation> | <library.name> | <library.revision>");
	println("");
	println("CPFILE: <library.cpFile>");
	println("LibFiles: <library.libFiles[0]>");

	for(libFile <- tail(library.libFiles)) 
	{
		println("  <libFile>");
	}
	println("");

	startTime = now();
	
	print("    Loading CPFILE...");
	cpModel = createM3FromLocation(libraryFolder + library.cpFile);
	println("Ok");

	print("    Loading LibFiles...");
	libModel = createM3FromJars(|project://libModel|, [ libraryFolder + libFile | libFile <- library.libFiles, libFile != "java-8-openjdk-amd64/jre/lib/" ]);
	println("Ok");

	print("    Merging Libraries model with JDK model...");
	libModel = composeM3(|project://libModel|, { libModel, jdkModel });
	println("Ok");
	
	differences = compareM3(cpModel, libModel, resultSet);
	
	//validateM3(cpModel);

	runningTime = now() - startTime;
	
	println("");
	println("    Library running time: <formatDuration(runningTime)>");
	
	return differences;
}

public M3 createM3FromLocation(loc location) 
{
	if(isDirectory(location)) 
	{
		 return createM3FromJars(location, findJars(location));
	}
	return createM3FromJar(location);
}

public M3 createM3FromJars(loc modelId, list[loc] jarFiles) 
{
	set[M3] models = { createM3FromJar(jar) | jar <- jarFiles };
	
	return composeM3(modelId, models);
}

public list[loc] findJars(loc location)
{
	list[loc] files = [ location + entry | entry <- listEntries(location) ];
	list[loc] jars = [ entry | entry <- files, entry.extension == "jar" ];

	for(file <- files) 
	{
		if(isDirectory(file)) 
		{
			jars = jars + findJars(file);
		}
	}
	return jars;
}

public str formatDuration(Duration duration) 
{
	str output = "";
	if(duration.hours < 10) 
	{
		output += "0";
	}
	output += "<duration.hours>:";

	if(duration.minutes < 10) 
	{
		output += "0";
	}
	output += "<duration.minutes>:";

	if(duration.seconds < 10) 
	{
		output += "0";
	}
	output += "<duration.seconds>";
	return output;
}



public list[str] compareM3(M3 cpModel, M3 libModel, result resultSet) 
{
	int project_classCount = size(classes(cpModel));
	int project_publicClassCount = size( { c | <c,m> <- cpModel.modifiers, isClass(c) && m == \public() } );
	int project_packageVisibleClassCount = project_classCount - project_publicClassCount;
	int project_anonymousClassCount = size({ c | <c,_> <- cpModel.declarations, c.scheme == "java+anonymousClass" });

	int project_enumCount = size(enums(cpModel));
	int project_publicEnumCount = size( { e | <e,m> <- cpModel.modifiers, isEnum(e) && m == \public() } );
	int project_packageVisibleEnumCount = project_enumCount - project_publicEnumCount;

	int project_interfaceCount = size(interfaces(cpModel));
	int project_publicInterfaceCount = size( { i | <i,m> <- cpModel.modifiers, isInterface(i) && m == \public() } );
	int project_packageVisibleInterfaceCount = project_interfaceCount - project_publicInterfaceCount;

	int project_methodCount = size(methods(cpModel));
	int project_publicMethods = size( { me | <me,m> <- cpModel.modifiers, isMethod(me) && m == \public() } );
	int project_protectedMethods = size( { me | <me,m> <- cpModel.modifiers, isMethod(me) && m == \protected() } );
	int project_privateMethods = size( { me | <me,m> <- cpModel.modifiers, isMethod(me) && m == \private() } );
	int project_packagePrivateMethods = project_methodCount - project_publicMethods - project_protectedMethods - project_privateMethods;

	int libraries_classCount = size(classes(libModel));
	int libraries_publicClassCount = size( { c | <c,m> <- libModel.modifiers, isClass(c) && m == \public() } );
	int libraries_packageVisibleClassCount = libraries_classCount - libraries_publicClassCount;
	int libraries_anonymousClassCount = size({ c | <c,_> <- libModel.declarations, c.scheme == "java+anonymousClass" });

	int libraries_enumCount = size(enums(libModel));
	int libraries_publicEnumCount = size( { e | <e,m> <- libModel.modifiers, isEnum(e) && m == \public() } );
	int libraries_packageVisibleEnumCount = libraries_enumCount - libraries_publicEnumCount;

	int libraries_interfaceCount = size(interfaces(libModel));
	int libraries_publicInterfaceCount = size( { i | <i,m> <- libModel.modifiers, isInterface(i) && m == \public() } );
	int libraries_packageVisibleInterfaceCount = libraries_interfaceCount - libraries_publicInterfaceCount;

	// Compensate for bug in Docker code.
	resultSet.project_interfaceCount  = resultSet.project_publicInterfaceCount + resultSet.project_packageVisibleInterfaceCount;
	resultSet.libraries_interfaceCount = resultSet.libraries_publicInterfaceCount + resultSet.libraries_packageVisibleInterfaceCount;


	println();
	println("	Project class count:                     <project_classCount>, <resultSet.project_classCount>"); 
	println("	Project public class count:              <project_publicClassCount>, <resultSet.project_publicClassCount>"); 
	println("	Project package visible count:           <project_packageVisibleClassCount>, <resultSet.project_packageVisibleClassCount>");
	println("	Project anonymous class count:           <project_anonymousClassCount>");
	println("	Project enum count:                      <project_enumCount>"); 
	println();
	println("	Project interface count:                 <project_interfaceCount>, <resultSet.project_interfaceCount>"); 
	println("	Project public interface count:          <project_publicInterfaceCount>, <resultSet.project_publicInterfaceCount>"); 
	println("	Project package visible interface count: <project_packageVisibleInterfaceCount>, <resultSet.project_packageVisibleInterfaceCount>"); 
	println();
	println("	Project method count:                    <project_methodCount>, <resultSet.project_methodCount>"); 
	println("	Project public method count:             <project_publicMethods>, <resultSet.project_publicMethods>"); 
	println("	Project protected method count:          <project_protectedMethods>, <resultSet.project_protectedMethods>"); 
	println("	Project package private method count:    <project_packagePrivateMethods>, <resultSet.project_packagePrivateMethods>"); 
	println("	Project private method count:            <project_privateMethods>, <resultSet.project_privateMethods>");
	println();
	println("	Libraries class count:                   <libraries_classCount + libraries_enumCount>, <resultSet.libraries_classCount>"); 
	println("	Libraries public class count:            <libraries_publicClassCount + libraries_publicEnumCount>, <resultSet.libraries_publicClassCount>"); 
	println("	Libraries package visible count:         <libraries_packageVisibleClassCount + libraries_packageVisibleEnumCount>, <resultSet.libraries_packageVisibleClassCount>");
	println("	Libraries anonymous class count:         <libraries_anonymousClassCount>");
	println();
	println("	Libraries interface count:               <libraries_interfaceCount>, <resultSet.libraries_interfaceCount>"); 
	println("	Libraries public interface count:        <libraries_publicInterfaceCount>, <resultSet.libraries_publicInterfaceCount>"); 
	println("	Libraries package visible interface count: <libraries_packageVisibleInterfaceCount>, <resultSet.libraries_packageVisibleInterfaceCount>"); 
	
	list[str] differences = [];
	bool differencesDetected = false;
	
	// In the Evaluation container enums are counted as classes.
	project_classCount += project_enumCount;
	project_publicClassCount += project_publicEnumCount;
	project_packageVisibleClassCount += project_packageVisibleEnumCount;
	
	if( project_classCount != resultSet.project_classCount
		|| project_publicClassCount != resultSet.project_publicClassCount
		|| project_packageVisibleClassCount != resultSet.project_packageVisibleClassCount
		|| project_publicInterfaceCount != resultSet.project_publicInterfaceCount
		|| project_packageVisibleInterfaceCount != resultSet.project_packageVisibleInterfaceCount)
	{
		differences += "Class/Interfaces differences detected in <cpModel.id>";
	
		differences += "	Project class count:                     <project_classCount>, <resultSet.project_classCount>";
		differences += "	Project pulic class count:               <project_publicClassCount>, <resultSet.project_publicClassCount>";
		differences += "	Project package visible class count:     <project_packageVisibleClassCount>, <resultSet.project_packageVisibleClassCount>";
		differences += "	Project anonymous class count:           <project_anonymousClassCount>";
		differences += "	Project enum count:                      <project_enumCount>";
		differences += "	Project pulic interface count:           <project_publicInterfaceCount>, <resultSet.project_publicInterfaceCount>";
		differences += "	Project package visible interface count: <project_packageVisibleInterfaceCount>, <resultSet.project_packageVisibleInterfaceCount>";
		differencesDetected  = true;
	} 

	if( project_methodCount != resultSet.project_methodCount
		|| project_publicMethods != resultSet.project_publicMethods
		|| project_protectedMethods != resultSet.project_protectedMethods 
		|| project_packagePrivateMethods != resultSet.project_packagePrivateMethods 
		|| project_privateMethods != resultSet.project_privateMethods) 
	{
		differences += "Method differences detected in <cpModel.id>";
		differences += "	Project method count:                    <project_methodCount>, <resultSet.project_methodCount>		<project_methodCount - resultSet.project_methodCount>";
		differences += "	Project public method count:             <project_publicMethods>, <resultSet.project_publicMethods>	<project_publicMethods - resultSet.project_publicMethods>";
		differences += "	Project protected method count:          <project_protectedMethods>, <resultSet.project_protectedMethods>";
		differences += "	Project pacakage private method count:   <project_packagePrivateMethods>, <resultSet.project_packagePrivateMethods>";
		differences += "	Project private method count:            <project_privateMethods>, <resultSet.project_privateMethods>";
		differencesDetected  = true;
	}

	if(!differencesDetected)
	{
		differences += "File <cpModel.id> has no differences.";
	}
	
	
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
	
	return differences;
} 

public void validateM3(M3 model) 
{
	set[loc]  notDeclared = {};
	
	
	notDeclared = carrier(model.methodInvocation) - domain(model.declarations);
	println("Undeclared method invocations: <size(notDeclared)>");
	
	notDeclared = { replaceAll(m.uri, "$", "/") | m <- carrier(model.methodInvocation) } - { replaceAll(m.uri, "$", "/" ) | m <- domain(model.declarations) };
	println("Undeclared method invocations when ignoring $ sign: <size(notDeclared)>");
	
	notDeclared = domain(model.modifiers) - domain(model.declarations);
	println("Undeclared element in modifiers: <size(notDeclared)>");
	
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

