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

alias AnalysisResult = tuple[
    loc modelId,
    // Class count
    int project_classCount,
    int project_packagePrivateClassCount,
    int project_purePackagePrivateClassCount,
    // 
    int project_totalMethodInvocationCount,
    int project_constructorInvocationCount,
    int project_privateMethodInvocationCount,
    int project_staticMethodInvocationCount,
    int project_virtualMethodInvocationCount,
    // 
    int project_possibleCallInstances,
    int project_packagePrivateCallInstances,
    int project_crossPackage_packagePrivateCallInstances
];



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

    for(library <- CompleteDataSet(), library.id in libraryIdentifiers) 
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
    
    println("    Repairing Complete M3 Model...");
    completeModel = repairM3For1145(completeModel);
    completeModel = repairM3For1129(completeModel);
    println("Ok");


    println("    Counting package-private method invocations...");
    println();
    /*
    AnalysisResult result = getPrivatePackegeInvocations(cpModel, completeModel);
    
    println("        Project class count:                                    <result.project_classCount>");
    println("        Project package-private class count:                    <result.project_packagePrivateClassCount>");
    println("        Project pure package-private class count:               <result.project_purePackagePrivateClassCount>");
    println("        Project total method invocation count:                  <result.project_totalMethodInvocationCount>");
//    println("        Project constructor invocation count:                   <result.project_constructorInvocationCount>");
  //  println("        Project private method invocatiojn count:               <result.project_privateMethodInvocationCount>");
    println("        Project virtual method invocation count:                <result.project_virtualMethodInvocationCount>");
    println("        Project possible call instance count:                   <result.project_possibleCallInstances>");
    println("        Project possible package-private call instance count:   <result.project_packagePrivateCallInstances>");
    println("        Project possible cross package-private call instances:  <result.project_crossPackage_packagePrivateCallInstances>");
    */
    println("");
    println("    Library running time: <formatDuration(now() - startTime)>");
    println("------------------------------------------------------------------------");
}

public AnalysisResult getPrivatePackegeInvocations(M3 model, M3 completeModel) 
{
    set[loc] overridenMethods = domain(completeModel.methodOverrides);
    set[loc] privateMethods = { method | <method,modifier> <- completeModel.modifiers, isMethod(method) && modifier == \private() };

    // Determine the se
    set[loc] methodInvocationSources = domain(model.methodInvocation);
    rel[loc from, loc to] methodInvocations = { <from,to> | <from,to> <- completeModel.methodInvocation, from in methodInvocationSources }; 


    //int constructorInvocationCount = size( { <from,to> | <from,to> <- methodInvocations, isConstructor(to)} );
    //int privateMethodInvocationCount = size( { <from,to> | <from,to> <- methodInvocations, !isConstructor(to) && to in privateMethods } );

    // First, select invocations of methods that can not be resolved by CHA. These include
    // - Invocations of methods that are overriden by at least one other method. (this implicitly also excludes invocations of static methods)      
    // - Except invocations of constructors.
    // - Except invocations of private methods since these can also be staticly resolved.
    rel[loc,loc] virtualMethodInvocations = { <from,to> | <from,to> <- methodInvocations, 
        to in overridenMethods && !isConstructor(to) && to notin privateMethods };

    // Determine the set of package-private classes.
    set[loc] packagePrivateClasses = { class | class <- classes(completeModel) + enums(completeModel), 
        <class,\public()> notin completeModel.modifiers && <class,\protected()> notin completeModel.modifiers && <class,\private()> notin completeModel.modifiers };
    
    // Determine the set of pure package-private classes. These are classes that are not subclassed by any public class.
    set[loc] publicExtends = { to | <from,to> <- completeModel.extends+, <from,\public()> in completeModel.modifiers && to in packagePrivateClasses };
    purePackagePrivateClasses = packagePrivateClasses - publicExtends;
    
    // Determine the set of methods that belong to a package-private class.
    set[loc] packagePrivateMethods = { method | <class,method> <- completeModel.containment, class in purePackagePrivateClasses && isMethod(method) }; 

    // Create a mapping relation from method to package.
    rel[loc,loc] outerPackages = completeModel.containment - { <x,y> | <x,y> <- completeModel.containment, isPackage(x) && isPackage(y) };
    map[loc method, loc package] methodPackages = ( y : x | <x,y> <- outerPackages+, isPackage(x) && isMethod(y) );
    
    
    rel[loc from, loc to] transitiveOverrides = completeModel.methodOverrides+;
    possibleMethodInvocations = { <from,override> | <from,override> <- (virtualMethodInvocations o transitiveOverrides), override in packagePrivateMethods };
    
    possiblePackagePrivateMethodInvocations = { <from,override> | <from,override> <- possibleMethodInvocations, override in packagePrivateMethods }; 
    
    crossPackageInvocations = { <from,override> | <from,override> <- possiblePackagePrivateMethodInvocations, methodPackages[from] != methodPackages[override] }; 
    
    return <
        model.id, //loc modelId,
        size(classes(model) + enums(model)), //int project_classCount,
        size(packagePrivateClasses), //int project_packagePrivateClassCount,
        size(purePackagePrivateClasses), //int project_purePackagePrivateClassCount,
        size(model.methodInvocation),  //int project_totalMethodInvocationCount
        -1, //int project_constructorInvocationCount,
        -1, //int project_privateMethodInvocationCount,
        -1, //int project_staticMethodInvocationCount,
        size(virtualMethodInvocations), //int project_virtualMethodInvocationCount,
        size(possibleMethodInvocations), ///nt project_possibleCallInstances,
        size(possiblePackagePrivateMethodInvocations), //int project_packagePrivateCallInstances,
        size(crossPackageInvocations) //int project_crossPackage_packagePrivateCallInstances
    >;
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




