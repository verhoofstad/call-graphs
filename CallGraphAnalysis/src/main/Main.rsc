module main::Main

import Prelude;
import List;
import util::Math;
import lang::java::m3::Core;
import lang::java::m3::AST;
import lang::java::jdt::m3::Core;
import lang::java::m3::TypeHierarchy;
import lang::java::m3::TypeSymbol;
import analysis::graphs::Graph;

import main::DataSet;
import main::ReachabilityAnalysis;
import main::cha::ClassHierarchyAnalysis;

import main::results::ResultSet;
import main::results::LoadResults;
import main::M3Repair;

// Options
public bool skipLibraries = true;

// Environmental settings
public loc libraryFolder = |file:///C:/CallGraphData/Libraries|;
public loc jdkFolder = |file:///C:/CallGraphData/JavaJDK/java-8-openjdk-amd64|;
public loc resultsFile = |file:///C:/CallGraphData/results.txt|;
public loc differencesFile = |file:///C:/CallGraphData/differences.csv|;
public loc packageVisibleFile = |file:///C:/CallGraphData/packageVisible.csv|;


alias M3Result = tuple[
    loc modelId,
    // Class count
    int classCount,
    int publicClassCount,
    int packagePrivateClassCount,
    int nestedClassCount,
    int publicNestedClassCount,
    int protectedNestedClassCount,
    int privateNestedClassCount,
    int packagePrivateNestedClassCount,
    real packagePrivateClassPercentage,
    // Enum count
    int enumCount,
    int publicEnumCount,
    int packagePrivateEnumCount,
    int nestedEnumCount,
    int publicNestedEnumCount,
    int protectedNestedEnumCount,
    int privateNestedEnumCount,
    int packagePrivateNestedEnumCount,
    // Package count
    int packagesWithPackagePrivateClasses,
    // Interface count
    int interfaceCount,
    int publicInterfaceCount,
    int packagePrivateInterfaceCount,
    // Method count
    int methodCount,
    int publicMethods,
    int protectedMethods,
    int privateMethods,
    int packagePrivateMethods,
    int volatileMethods,
    int publicVolatileMethods,
    int objectMethodInvocation
];

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
    M3 jdkModel;
    if(skipLibraries) 
    {
        jdkModel = m3(|project://empty|);
        println("Skipped");
    } 
    else
    {
        jdkModel = createM3FromLocation(jdkFolder);
        println("Ok");
    }
    println();

    // Create an output file.
    str header = "description;Rascal Count;Opal Count";
    writeFile(differencesFile, "<header>\r\n");

    // Create an output file for package visibility 
    header = "organisation;name;revision;public_classes;package_private_classes;percentage;packages;object_method_invocation";
    writeFile(packageVisibleFile, "<header>\r\n");

	for(library <- TestDataSet, library.id in libraryIdentifiers) 
	{
		resultSet = resultsOf(results, library.organisation,  library.name, library.revision);
	
		analyseJar(library, resultSet, jdkModel);
	}

	println("");
	println("Total running time: <formatDuration(now() - startTime)>");
}

public void analyseJar(Library library, Result resultSet, M3 jdkModel) 
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
	print("    Repairing CPModel...");
	cpModel = repairM3For1129(cpModel);
	println("Ok");
	

    print("    Counting code elements in CP Model...");
	cpResults = countElements(cpModel);
	println("Ok");
	
	M3Result libResults;
	
    if(!skipLibraries) {

		print("    Loading LibFiles...");
		libModel = createM3FromJars(|project://libModel|, [ libraryFolder + libFile | libFile <- library.libFiles, libFile != "java-8-openjdk-amd64/jre/lib/" ]);
		println("Ok");
		
		print("    Merging Libraries model with JDK model...");
		libModel = composeM3(|project://libModel|, { libModel, jdkModel });
		println("Ok");

		print("    Counting code elements in Libraries...");
	    libResults = countElements(libModel);
	    println("Ok");
	}

	printProjectComparison(cpResults, resultSet);

	appendProjectResultsToOutputFile(cpResults, resultSet);
	
	appendPackageVisibilityToOutputFile(library, cpResults);

    if(!skipLibraries) {

		printLibrariesComparison(libResults, resultSet);
		appendLibrariesResultToOutputFile(libResults, resultSet);
	}
	
	println("");
	println("    Library running time: <formatDuration(now() - startTime)>");
    println("------------------------------------------------------------------------");
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

public M3 loadLib(int libraryId) 
{
    return createM3FromJar(libraryFolder + TestDataSet[libraryId].cpFile);
}
public list[int] smallJars() = [2..99] - [3] - [25];

public list[loc] findJars(loc location)
{
	list[loc] files = [ location + entry | entry <- listEntries(location) ];
	list[loc] jars = [ entry | entry <- files, entry.extension == "jar" ];
	
	return (jars | it + findJars(file) | file <- files, isDirectory(file) );
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


public void appendPackageVisibilityToOutputFile(Library library, M3Result results) 
{
    str packagePrivateClassPercentageStr = replaceAll(toString(results.packagePrivateClassPercentage), ".", ",");
    
    appendToFile(packageVisibleFile, "<library.organisation>;<library.name>;<library.revision>;<results.classCount>;<results.packagePrivateClassCount>;<packagePrivateClassPercentageStr>%;<results.packagesWithPackagePrivateClasses>;<results.objectMethodInvocation>\r\n");
}


public M3Result countElements(M3 model) 
{
    set[loc] allClasses = classes(model);
    int classCount = size(allClasses);
    
    // Inner classes, static nested classes, anonymous classes and local classes.
    set[loc] nestedClasses = { class | <container, class> <- model.containment, (isMethod(container) || isClass(container)) && class in allClasses };
    // Divide the nested classes in public, protected, package-private and private classes.
    set[loc] publicNestedClasses = { class | class <- nestedClasses, <class,\public()> in model.modifiers };
    set[loc] protectedNestedClasses = { class | class <- nestedClasses, <class,\protected()> in model.modifiers };
    set[loc] privateNestedClasses = { class | class <- nestedClasses, <class,\private()> in model.modifiers };
    set[loc] packagePrivateNestedClasses = nestedClasses - publicNestedClasses - protectedNestedClasses - privateNestedClasses; 
    
    // Outer classes  
    set[loc] outerClasses = allClasses - nestedClasses;
    // Divide the outer classes in public classes and package-private classes.
    set[loc] publicClasses = { class | class <- outerClasses, <class,\public()> in model.modifiers }; 
    set[loc] packagePrivateClasses = outerClasses - publicClasses;
    
    int publicClassCount = size( publicClasses );
    int packagePrivateClassCount = size(packagePrivateClasses);
    
    real packagePrivateClassPercentage = 0.0;
    if(classCount > 0) {
        packagePrivateClassPercentage = packagePrivateClassCount / toReal(classCount) * 100;
    }

    // Enumerations
    set[loc] allEnums = enums(model);
    
    // Nested enums
    set[loc] nestedEnums = { enum | <container, enum> <- model.containment, (isMethod(container) || isClass(container)) && enum in allEnums };
    // Divide the nested enums in public, protected, package-private and private enums.
    set[loc] publicNestedEnums = { enum | enum <- nestedEnums, <enum,\public()> in model.modifiers };
    set[loc] protectedNestedEnums = { enum | enum <- nestedEnums, <enum,\protected()> in model.modifiers };
    set[loc] privateNestedEnums = { enum | enum <- nestedEnums, <enum,\private()> in model.modifiers };
    set[loc] packagePrivateNestedEnums = nestedEnums - publicNestedEnums - protectedNestedEnums - privateNestedEnums; 
    
    // Outer enums  
    set[loc] outerEnums = allEnums - nestedEnums;
    // Divide the outer classes in public classes and package-private classes.
    set[loc] publicEnums = { enum | enum <- outerEnums, <enum,\public()> in model.modifiers }; 
    set[loc] packagePrivateEnums = outerEnums - publicEnums;
    


    int packagesWithPackagePrivateClasses = size({ <package> | <package,class> <-  model.containment o model.containment, 
        isPackage(package) && class in packagePrivateClasses });
        
    int enumCount = size(enums(model));

    int interfaceCount = size(interfaces(model));
    int publicInterfaceCount = size( { i | <i,m> <- model.modifiers, isInterface(i) && m == \public() } );
    int packageVisibleInterfaceCount = interfaceCount - publicInterfaceCount;

    set[loc] allMethods = { m | <m,_> <- model.declarations, isMethod(m) || m.scheme == "java+initializer" };
    rel[loc,Modifier] methodModifiers = { <me,m> | <me,m> <- model.modifiers, me in allMethods };
    
    int methodCount = size(allMethods);
    int publicMethods = size( { me | <me,m> <- methodModifiers, m == \public() } );
    int protectedMethods = size( { me | <me,m> <- methodModifiers, m == \protected() } );
    int privateMethods = size( { me | <me,m> <- methodModifiers, m == \private() } );
    int packagePrivateMethods = methodCount - publicMethods - protectedMethods - privateMethods;
    
    set[loc] allVolatileMethods = { me | <me,m> <- methodModifiers, m == \volatile() };
    set[loc] publicVolatileMethods = { me | <me,m> <- methodModifiers, m == \public() && me in allVolatileMethods };
    
    int objectMethodInvocation = size({ <x,y> | <x,y> <- model.methodInvocation, contains(y.path, "/java/lang/Object/") && !isConstructor(y) });
    
    return <
        model.id,
        size(allClasses),
        publicClassCount,
        packagePrivateClassCount,
        size(nestedClasses),
        size(publicNestedClasses),
        size(protectedNestedClasses),
        size(privateNestedClasses),
        size(packagePrivateNestedClasses),
        packagePrivateClassPercentage,
        enumCount,
        size(publicEnums),
        size(packagePrivateEnums),
        size(nestedEnums),
        size(publicNestedEnums),
        size(protectedNestedEnums),
        size(privateNestedEnums),
        size(packagePrivateNestedEnums),
        packagesWithPackagePrivateClasses,
        interfaceCount,
        publicInterfaceCount,
        packageVisibleInterfaceCount,
        methodCount,
        publicMethods,
        protectedMethods,
        privateMethods,
        packagePrivateMethods,
        size(allVolatileMethods),
        size(publicVolatileMethods),
        objectMethodInvocation
    >;
}


public void printProjectComparison(M3Result cpResults, Result resultSet) 
{
    int totalPublicClassCount = cpResults.publicClassCount + cpResults.publicNestedClassCount + cpResults.protectedNestedClassCount
        + cpResults.publicEnumCount + cpResults.publicNestedEnumCount + cpResults.protectedNestedEnumCount;
    int totalPackagePrivateClassCount = cpResults.packagePrivateClassCount + cpResults.packagePrivateNestedClassCount+ cpResults.privateNestedClassCount
        + cpResults.packagePrivateEnumCount + cpResults.packagePrivateNestedEnumCount + cpResults.privateNestedEnumCount;

    println();
    printStat("Project class count", cpResults.classCount);
    printStat("  Project outer class count",  cpResults.publicClassCount + cpResults.packagePrivateClassCount );
    printStat("    Public outer class count", cpResults.publicClassCount);
    printStat("    Package-private class count", cpResults.packagePrivateClassCount);
    printStat("  Project nested class count", cpResults.nestedClassCount);
    printStat("    Public nested class count", cpResults.publicNestedClassCount);
    printStat("    Protected nested class count", cpResults.protectedNestedClassCount);
    printStat("    Package-private nested class count", cpResults.packagePrivateNestedClassCount);
    printStat("    Private nested class count", cpResults.privateNestedClassCount);

    printStat("Project enum count", cpResults.enumCount);
    printStat("  Project outer enum count",  cpResults.publicEnumCount + cpResults.packagePrivateEnumCount );
    printStat("    Public outer enum count", cpResults.publicEnumCount);
    printStat("    Package-private enum count", cpResults.packagePrivateEnumCount);
    printStat("  Project nested enum count", cpResults.nestedEnumCount);
    printStat("    Public nested enum count", cpResults.publicNestedEnumCount);
    printStat("    Protected nested enum count", cpResults.protectedNestedEnumCount);
    printStat("    Package-private nested enum count", cpResults.packagePrivateNestedEnumCount);
    printStat("    Private nested enum count", cpResults.privateNestedEnumCount);

    printStat("Project total class count", cpResults.classCount + cpResults.enumCount, resultSet.project_classCount);
    printStat("Project public class count", totalPublicClassCount, resultSet.project_publicClassCount); 
    printStat("Project package private count", totalPackagePrivateClassCount, resultSet.project_packageVisibleClassCount);
    println("    Project package visible class percentage     :  <right("<round(cpResults.packagePrivateClassPercentage, 0.1)>", 6)> %");
    println();
    printStat("Project interface count", cpResults.interfaceCount, resultSet.project_interfaceCount); 
    printStat("Project public interface count", cpResults.publicInterfaceCount, resultSet.project_publicInterfaceCount); 
    printStat("Project package visible interface count", cpResults.packagePrivateInterfaceCount, resultSet.project_packageVisibleInterfaceCount); 
    println();
    printStat("Project method count", cpResults.methodCount, resultSet.project_methodCount); 
    printStat("Project public method count", cpResults.publicMethods, resultSet.project_publicMethods); 
    printStat("Project protected method count", cpResults.protectedMethods, resultSet.project_protectedMethods); 
    printStat("Project package private method count", cpResults.packagePrivateMethods, resultSet.project_packagePrivateMethods); 
    printStat("Project private method count", cpResults.privateMethods, resultSet.project_privateMethods);
    printStat("Project volatile method count", cpResults.volatileMethods);
    printStat("Project public volatile method count", cpResults.publicVolatileMethods);
    
    println();
}

public void printLibrariesComparison(M3Result libResults, Result resultSet) 
{
    int totalPublicClassCount = libResults.publicClassCount + libResults.publicNestedClassCount + libResults.protectedNestedClassCount
        + libResults.publicEnumCount + libResults.publicNestedEnumCount + libResults.protectedNestedEnumCount;
    int totalPackagePrivateClassCount = libResults.packagePrivateClassCount + libResults.packagePrivateNestedClassCount+ libResults.privateNestedClassCount
        + libResults.packagePrivateEnumCount + libResults.packagePrivateNestedEnumCount + libResults.privateNestedEnumCount;

    println();
    printStat("Libraries class count", libResults.classCount + libResults.enumCount, resultSet.libraries_classCount); 
    printStat("Libraries public class count", totalPublicClassCount, resultSet.libraries_publicClassCount); 
    printStat("Libraries package visible count", totalPackagePrivateClassCount, resultSet.libraries_packageVisibleClassCount);
    println("    Libraries package visible class percentage:  <right("<round(libResults.packagePrivateClassPercentage, 0.1)>", 6)> %");
    println();
    printStat("Libraries interface count", libResults.interfaceCount, resultSet.libraries_interfaceCount); 
    printStat("Libraries public interface count", libResults.publicInterfaceCount, resultSet.libraries_publicInterfaceCount); 
    printStat("Libraries package visible interface count", libResults.packagePrivateInterfaceCount, resultSet.libraries_packageVisibleInterfaceCount); 
    println();
    printStat("Libraries method count", libResults.methodCount, resultSet.libraries_methodCount); 
    printStat("Libraries public method count", libResults.publicMethods, resultSet.libraries_publicMethods); 
    printStat("Libraries protected method count", libResults.protectedMethods, resultSet.libraries_protectedMethods); 
    printStat("Libraries package private method count", libResults.packagePrivateMethods, resultSet.libraries_packagePrivateMethods); 
    printStat("Libraries private method count", libResults.privateMethods, resultSet.libraries_privateMethods);
    println();
}

public void printStat(str description, int value1) 
{
    println("    <left(description, 45, " ")>:  <right("<value1>", 6, " ")>");
}

public void printStat(str description, int value1, int value2) 
{
    int diff = value1 - value2;
    str diffText = (diff > 0) ? "+<diff>" : (diff < 0) ? "<diff>" : "";
    
    println("    <left(description, 45, " ")>:  <right("<value1>", 6, " ")>  <right("<value2>", 6, " ")>  <right(diffText, 6, " ")>");
}


public void appendProjectResultsToOutputFile(M3Result cpResults, Result resultSet) 
{
    appendToFile(differencesFile, "<resultSet.organisation> <resultSet.name> <resultSet.revision>;;\r\n"); 
    appendToFile(differencesFile, "Project class count;<cpResults.classCount>;<resultSet.project_classCount>\r\n"); 
    appendToFile(differencesFile, "Project public class count;<cpResults.publicClassCount>;<resultSet.project_publicClassCount>\r\n"); 
    appendToFile(differencesFile, "Project package visible count;<cpResults.packagePrivateClassCount>;<resultSet.project_packageVisibleClassCount>\r\n");
    appendToFile(differencesFile, "Project package visible class percentage;<cpResults.packagePrivateClassPercentage>\r\n");
    appendToFile(differencesFile, "Project interface count;<cpResults.interfaceCount>;<resultSet.project_interfaceCount>\r\n"); 
    appendToFile(differencesFile, "Project public interface count;<cpResults.publicInterfaceCount>;<resultSet.project_publicInterfaceCount>\r\n"); 
    appendToFile(differencesFile, "Project package visible interface count;<cpResults.packagePrivateInterfaceCount>;<resultSet.project_packageVisibleInterfaceCount>\r\n"); 
    appendToFile(differencesFile, "Project method count;<cpResults.methodCount>;<resultSet.project_methodCount>\r\n"); 
    appendToFile(differencesFile, "Project public method count;<cpResults.publicMethods>;<resultSet.project_publicMethods>\r\n"); 
    appendToFile(differencesFile, "Project protected method count;<cpResults.protectedMethods>;<resultSet.project_protectedMethods>\r\n"); 
    appendToFile(differencesFile, "Project package private method count;<cpResults.packagePrivateMethods>;<resultSet.project_packagePrivateMethods>\r\n"); 
    appendToFile(differencesFile, "Project private method count;<cpResults.privateMethods>;<resultSet.project_privateMethods>\r\n");
}

public void appendLibrariesResultToOutputFile(M3Result libResults, Result resultSet) 
{
    appendToFile(differencesFile, "Libraries class count;<libResults.classCount>;<resultSet.libraries_classCount>\r\n"); 
    appendToFile(differencesFile, "Libraries public class count;<libResults.publicClassCount>;<resultSet.libraries_publicClassCount>\r\n"); 
    appendToFile(differencesFile, "Libraries package visible count;<libResults.packagePrivateClassCount>;<resultSet.libraries_packageVisibleClassCount>\r\n");
    appendToFile(differencesFile, "Libraries package visible class percentage;<libResults.packagePrivateClassPercentage>\r\n");
    appendToFile(differencesFile, "Libraries interface count;<libResults.interfaceCount>;<resultSet.libraries_interfaceCount>\r\n"); 
    appendToFile(differencesFile, "Libraries public interface count;<libResults.publicInterfaceCount>;<resultSet.libraries_publicInterfaceCount>\r\n"); 
    appendToFile(differencesFile, "Libraries package visible interface count;<libResults.packagePrivateInterfaceCount>;<resultSet.libraries_packageVisibleInterfaceCount>\r\n"); 
    appendToFile(differencesFile, "Libraries method count;<libResults.methodCount>;<resultSet.libraries_methodCount>\r\n"); 
    appendToFile(differencesFile, "Libraries public method count;<libResults.publicMethods>;<resultSet.libraries_publicMethods>\r\n"); 
    appendToFile(differencesFile, "Libraries protected method count;<libResults.protectedMethods>;<resultSet.libraries_protectedMethods>\r\n"); 
    appendToFile(differencesFile, "Libraries package private method count;<libResults.packagePrivateMethods>;<resultSet.libraries_packagePrivateMethods>\r\n"); 
    appendToFile(differencesFile, "Libraries private method count;<libResults.privateMethods>;<resultSet.libraries_privateMethods>\r\n");
}

public tuple[loc from, loc to] getPrivatePackegeInvocations(M3 model) 
{
    possibleMethodInvocations = model.methodInvocation o model.methodOverrides;
    
    
        
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
    list[loc] jdkFiles = findJars(jdkFolder); 

    for(loc jdkFile <- jdkFiles) 
    {
        println("Stats for <jdkFile>:");
        println();

        M3 model = createM3FromJar(jdkFile);

        int packageCount = size({ d | <d,_> <- model.declarations, d.scheme == "java+package" });
        int methodCount = size(methods(model));
        int classFileCount = size({ d | <d,_> <- model.declarations, d.scheme == "java+compilationUnit" });
        
        println("Package count:     <packageCount>");
        println("Method count:      <methodCount>");
        println("Class file count:  <classFileCount>");
        println();
        println();
    }
}

