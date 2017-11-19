module main::analysis::packagePrivate::Main

import Prelude;
import List;
import util::Math;
import lang::java::m3::Core;
import lang::java::m3::AST;
import lang::java::jdt::m3::Core;
import lang::java::m3::TypeHierarchy;
import lang::java::m3::TypeSymbol;
import analysis::graphs::Graph;

import main::DateTime;
import main::Util;
import main::analysis::DataSet;
import main::analysis::Util;
import main::M3Repair;

// Environmental settings
public loc packageVisibleFile = |file:///C:/CallGraphData/packageVisible.csv|;


public void analyseJars() 
{
    analyseJars([0..99]);
}


public void analyseJars(list[int] libraryIdentifiers) 
{
    startTime = now();
    print("Loading Java JDK Libraries...");

    M3 jdkModel = createM3FromLocation(jdkFolder);
    println("Ok (Time <formatDuration(now() - startTime)>)");

    startTime = now();    
    println("Repairing Java JDK Libraries model...");
    jdkStartTime = now();
    jdKModel = repairM3For1145(jdkModel);
    jdkModel = repairM3For1129(jdkModel);        
    println("Ok (Time <formatDuration(now() - jdkStartTime)>)");
  
    analyseJars(libraryIdentifiers, jdkModel);
}

public void analyseJars(list[int] libraryIdentifiers, M3 jdkModel) 
{
    startTime = now();

    for(library <- TestDataSet, library.id in libraryIdentifiers) 
    {
        analyseJar(library, jdkModel);
    }
    
    println();

    println();
    println("Total running time: <formatDuration(now() - startTime)>");
}

public void analyseJar(Library library, M3 jdkModel) 
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
        
    print("    Merging Project model with Libraries model and JDK model...");
    completeModel = composeM3(|project://complete|, { cpModel, libModel, jdkModel } );
    println("Ok");
    
    print("    Repairing Complete M3 Model...");
    completeModel = repairM3For1145(completeModel);
    completeModel = repairM3For1129(completeModel);
    println("Ok");


    println("    Counting package-private method invocations...");
    println();
    
    getPrivatePackegeInvocations(completeModel, cpModel);
    
    
    println("");
    println("    Library running time: <formatDuration(now() - startTime)>");
    println("------------------------------------------------------------------------");
}

public void getPrivatePackegeInvocations(M3 model, M3 targetModel) 
{
    set[loc] overridenMethods = domain(model.methodOverrides);
    set[loc] privateMethods = { method | <method,modifier> <- model.modifiers, isMethod(method) && modifier == \private() };


    // First, select invocations of methods that can not be resolved by CHA. These include
    // - Invocations of methods that are overriden by at least one other method. (this implicitly also excludes invocations of static methods)      
    // - Except invocations of constructors.
    // - Except invocations of private methods since these can also be staticly resolved.
    rel[loc,loc] virtualMethodInvocations = { <from,to> | <from,to> <- targetModel.methodInvocation, 
        to in overridenMethods && !isConstructor(to) && to notin privateMethods };

    // Determine the set of package-private classes.
    set[loc] packagePrivateClasses = classes(model) + enums(model) - { c | <c,m> <- model.modifiers, m == \public() || m == \protected() || m == \private() };

    // Determine the set of methods that belong to a package-private class.
    set[loc] packagePrivateMethods = { method | <class,method> <- model.containment, class in packagePrivateClasses && isMethod(method) }; 

    // Create a mapping relation from method to package.
    rel[loc,loc] outerPackages = model.containment - { <x,y> | <x,y> <- model.containment, isPackage(x) && isPackage(y) };
    map[loc method, loc package] methodPackages = ( y : x | <x,y> <- outerPackages+, isPackage(x) && isMethod(y) );
    
    
    rel[loc from, loc to] transitiveOverrides = model.methodOverrides+;
    possibleMethodInvocations = { <from,override> | <from,override> <- (virtualMethodInvocations o transitiveOverrides), override in packagePrivateMethods };

    
    possiblePackagePrivateMethodInvocations = { <from,override> | <from,override> <- possibleMethodInvocations, override in packagePrivateMethods }; 
    
    crossPackageInvocations = { <from,override> | <from,override> <- possiblePackagePrivateMethodInvocations, methodPackages[from] != methodPackages[override] }; 
    
    
    int virtualMethodInvocationCount = size(virtualMethodInvocations);
    int possibleMethodInvocationCount = size(possibleMethodInvocations);
    int possiblePackagePrivateMethodInvocationCount = size(possiblePackagePrivateMethodInvocations);
    int crossPackageInvocationsCount = size(crossPackageInvocations);
    
    println("   Total virtual method invocations:                   <virtualMethodInvocationCount>");
    println("   Total possible method invocations:                  <possibleMethodInvocationCount>");
    println("   Total possible package-private method invocations:  <possiblePackagePrivateMethodInvocationCount>");
    println("   Total cross package method invocations:             <crossPackageInvocationsCount>");
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




