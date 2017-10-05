module main::Main

import Prelude;
import List;
import util::Math;
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

public list[str] analyseJar(Library library, Result resultSet, M3 jdkModel) 
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


public Result countElements(M3 cpModel, M3 libModel) 
{
}


public list[str] compareM3(M3 cpModel, M3 libModel, Result resultSet) 
{
    int project_classCount = size(classes(cpModel));
    int project_publicClassCount = size( { c | <c,m> <- cpModel.modifiers, isClass(c) && m == \public() } );
    int project_packageVisibleClassCount = project_classCount - project_publicClassCount;
    
    real project_packageVisibleClassPercentage = project_packageVisibleClassCount / toReal(project_classCount) * 100;

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

    int libraries_enumCount = size(enums(libModel));
    int libraries_publicEnumCount = size( { e | <e,m> <- libModel.modifiers, isEnum(e) && m == \public() } );
    int libraries_packageVisibleEnumCount = libraries_enumCount - libraries_publicEnumCount;

    int libraries_interfaceCount = size(interfaces(libModel));
    int libraries_publicInterfaceCount = size( { i | <i,m> <- libModel.modifiers, isInterface(i) && m == \public() } );
    int libraries_packageVisibleInterfaceCount = libraries_interfaceCount - libraries_publicInterfaceCount;

    int libraries_methodCount = size(methods(libModel));
    int libraries_publicMethods = size( { me | <me,m> <- libModel.modifiers, isMethod(me) && m == \public() } );
    int libraries_protectedMethods = size( { me | <me,m> <- libModel.modifiers, isMethod(me) && m == \protected() } );
    int libraries_privateMethods = size( { me | <me,m> <- libModel.modifiers, isMethod(me) && m == \private() } );
    int libraries_packagePrivateMethods = libraries_methodCount - libraries_publicMethods - libraries_protectedMethods - libraries_privateMethods;

    // Compensate for bug in Docker code.
    resultSet.project_interfaceCount  = resultSet.project_publicInterfaceCount + resultSet.project_packageVisibleInterfaceCount;
    resultSet.libraries_interfaceCount = resultSet.libraries_publicInterfaceCount + resultSet.libraries_packageVisibleInterfaceCount;
    
    // Enums are counted as classes.
    project_classCount += project_enumCount;
    project_publicClassCount += project_publicEnumCount;
    project_packageVisibleClassCount += project_packageVisibleEnumCount;
    
    libraries_classCount += libraries_enumCount;
    libraries_publicClassCount += libraries_publicEnumCount;
    libraries_packageVisibleClassCount += libraries_packageVisibleEnumCount;

    println();
    printStat("Project class count", project_classCount, resultSet.project_classCount); 
    printStat("Project public class count", project_publicClassCount, resultSet.project_publicClassCount); 
    printStat("Project package visible count", project_packageVisibleClassCount, resultSet.project_packageVisibleClassCount);
    printStat("Project enum count", project_enumCount); 
    println("    Project package visible class percentage : <project_packageVisibleClassPercentage>%");
    println();
    printStat("Project interface count", project_interfaceCount, resultSet.project_interfaceCount); 
    printStat("Project public interface count", project_publicInterfaceCount, resultSet.project_publicInterfaceCount); 
    printStat("Project package visible interface count", project_packageVisibleInterfaceCount, resultSet.project_packageVisibleInterfaceCount); 
    println();
    printStat("Project method count", project_methodCount, resultSet.project_methodCount); 
    printStat("Project public method count", project_publicMethods, resultSet.project_publicMethods); 
    printStat("Project protected method count", project_protectedMethods, resultSet.project_protectedMethods); 
    printStat("Project package private method count", project_packagePrivateMethods, resultSet.project_packagePrivateMethods); 
    printStat("Project private method count", project_privateMethods, resultSet.project_privateMethods);
    println();
    printStat("Libraries class count", libraries_classCount, resultSet.libraries_classCount); 
    printStat("Libraries public class count", libraries_publicClassCount, resultSet.libraries_publicClassCount); 
    printStat("Libraries package visible count", libraries_packageVisibleClassCount, resultSet.libraries_packageVisibleClassCount);
    printStat("Libraries enum count", libraries_enumCount);
    println();
    printStat("Libraries interface count", libraries_interfaceCount, resultSet.libraries_interfaceCount); 
    printStat("Libraries public interface count", libraries_publicInterfaceCount, resultSet.libraries_publicInterfaceCount); 
    printStat("Libraries package visible interface count", libraries_packageVisibleInterfaceCount, resultSet.libraries_packageVisibleInterfaceCount); 
    println();
    printStat("Libraries method count", libraries_methodCount, resultSet.libraries_methodCount); 
    printStat("Libraries public method count", libraries_publicMethods, resultSet.libraries_publicMethods); 
    printStat("Libraries protected method count", libraries_protectedMethods, resultSet.libraries_protectedMethods); 
    printStat("Libraries package private method count", libraries_packagePrivateMethods, resultSet.libraries_packagePrivateMethods); 
    printStat("Libraries private method count", libraries_privateMethods, resultSet.libraries_privateMethods);
    println();
    
    list[str] differences = [];
    bool differencesDetected = false;
    
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

public void printStat(str description, int value1) 
{
    println("    <left(description, 41, " ")>:  <right("<value1>", 6, " ")>");
}
public void printStat(str description, int value1, int value2) 
{
    int diff = value1 - value2;
    str diffText = (diff > 0) ? "+<diff>" : (diff < 0) ? "<diff>" : "";
    
    println("    <left(description, 41, " ")>:  <right("<value1>", 6, " ")>  <right("<value2>", 6, " ")>  <right(diffText, 6, " ")>");
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


public void analyseJDK() 
{
    list[loc] jdkFiles = [|file:///C:/CallGraphData/JavaJDK/java-8-openjdk-amd64/jre/lib/charsets.jar|,
        |file:///C:/CallGraphData/JavaJDK/java-8-openjdk-amd64/jre/lib/jce.jar|,
        |file:///C:/CallGraphData/JavaJDK/java-8-openjdk-amd64/jre/lib/jsse.jar|,
        |file:///C:/CallGraphData/JavaJDK/java-8-openjdk-amd64/jre/lib/management-agent.jar|,
        |file:///C:/CallGraphData/JavaJDK/java-8-openjdk-amd64/jre/lib/resources.jar|,
        |file:///C:/CallGraphData/JavaJDK/java-8-openjdk-amd64/jre/lib/rt.jar|,
        |file:///C:/CallGraphData/JavaJDK/java-8-openjdk-amd64/jre/lib/ext/cldrdata.jar|,
        |file:///C:/CallGraphData/JavaJDK/java-8-openjdk-amd64/jre/lib/ext/dnsns.jar|,
        |file:///C:/CallGraphData/JavaJDK/java-8-openjdk-amd64/jre/lib/ext/icedtea-sound.jar|,
        |file:///C:/CallGraphData/JavaJDK/java-8-openjdk-amd64/jre/lib/ext/jaccess.jar|,
        |file:///C:/CallGraphData/JavaJDK/java-8-openjdk-amd64/jre/lib/ext/java-atk-wrapper.jar|,
        |file:///C:/CallGraphData/JavaJDK/java-8-openjdk-amd64/jre/lib/ext/localedata.jar|,
        |file:///C:/CallGraphData/JavaJDK/java-8-openjdk-amd64/jre/lib/ext/nashorn.jar|,
        |file:///C:/CallGraphData/JavaJDK/java-8-openjdk-amd64/jre/lib/ext/sunec.jar|,
        |file:///C:/CallGraphData/JavaJDK/java-8-openjdk-amd64/jre/lib/ext/sunjce_provider.jar|,
        |file:///C:/CallGraphData/JavaJDK/java-8-openjdk-amd64/jre/lib/ext/sunpkcs11.jar|,
        |file:///C:/CallGraphData/JavaJDK/java-8-openjdk-amd64/jre/lib/ext/zipfs.jar|,
        |file:///C:/CallGraphData/JavaJDK/java-8-openjdk-amd64/jre/lib/security/local_policy.jar|,
        |file:///C:/CallGraphData/JavaJDK/java-8-openjdk-amd64/jre/lib/security/US_export_policy.jar|];

    for(loc jdkFile <- jdkFiles) 
    {
        M3 model = createM3FromJar(jdkFile);

        int packageCount = size({ d | <d,_> <- model.declarations, d.scheme == "java+package" });
        int methodCount = size(methods(model));
        int classFileCount = size({ d | <d,_> <- model.declarations, d.scheme == "java+compilationUnit" });
        
        println("Stats for <jdkFile>:");
        println();
        println("Package count:     <packageCount>");
        println("Method count:      <methodCount>");
        println("Class file count:  <classFileCount>");
        println();
        println();
    }
}

