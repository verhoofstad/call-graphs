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
public loc packagePrivateFile = |file:///C:/CallGraphData/packagePrivateAnalysis.csv|;


alias AnalysisResult = tuple[
    loc modelId,
    // Class count
    int project_classCount,
    int project_packagePrivateClassCount,
    int project_purePackagePrivateClassCount,
    int project_packagePrivateMethodCount,
    // 
    int project_totalMethodInvocationCount,
    int project_unresolveableMethodInvocationCount,
    int project_constructorInvocationCount,
    int project_privateMethodInvocationCount,
    int project_staticMethodInvocationCount,
    int project_monomorphicVirtualMethodInvocationCount,
    int project_virtualMethodInvocationCount,
    // 
    int project_possibleCallInstances,
    int project_packagePrivateCallInstances,
    int project_crossPackage_packagePrivateCallInstances,

    int total_packagePrivateClassCount,
    int total_purePackagePrivateClassCount,
    int total_instantiatedPurePackagePrivateClasses,
    int total_packagePrivateMethodCount
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

    // Create an output file.
    str header = "id;organisation;name;revision;project_classCount;project_packagePrivateClassCount;project_purePackagePrivateClassCount;project_packagePrivateMethodCount;" 
        + "project_totalMethodInvocationCount;project_unresolveableMethodInvocationCount;project_constructorInvocationCount;project_privateMethodInvocationCount;"
        + "project_staticMethodInvocationCount;project_monomorphicVirtualMethodInvocationCount;project_virtualMethodInvocationCount;project_possibleCallInstances;"
        + "project_packagePrivateCallInstances;project_crossPackage_packagePrivateCallInstances;total_packagePrivateClassCount;total_purePackagePrivateClassCount;"
        + "total_instantiatedPurePackagePrivateClasses;total_packagePrivateMethodCount";
    writeFile(packagePrivateFile, "<header>\r\n");


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


    println("    Counting package-private method invocations...");
    println();

    AnalysisResult result = getPrivatePackegeInvocations(cpModel, completeModel);
    
    int totalProjectMethodInvocationCount = result.project_constructorInvocationCount + result.project_unresolveableMethodInvocationCount + result.project_privateMethodInvocationCount
        + result.project_staticMethodInvocationCount + result.project_monomorphicVirtualMethodInvocationCount + result.project_virtualMethodInvocationCount;
    
    println("        Project class count:                                    <result.project_classCount>");
    println("        Project package-private class count:                    <result.project_packagePrivateClassCount>");
    println("        Project pure package-private class count:               <result.project_purePackagePrivateClassCount>");
    println("        Project package-private method count:                   <result.project_packagePrivateMethodCount>");
    println("        Project total method invocation count:                  <result.project_totalMethodInvocationCount>");
    println("           - Unresolveable invocation count:                    <result.project_unresolveableMethodInvocationCount>");
    println("           - Constructor invocation count:                      <result.project_constructorInvocationCount>");
    println("           - Private method invocation count:                   <result.project_privateMethodInvocationCount>");
    println("           - Static method invocation count:                    <result.project_staticMethodInvocationCount>");
    println("           - Monomorphic method invocation count:               <result.project_monomorphicVirtualMethodInvocationCount>");
    println("           - Virtual method invocation count:                   <result.project_virtualMethodInvocationCount>");
    println("           - Total:                                             <totalProjectMethodInvocationCount>");
    println("        Project possible call instance count:                   <result.project_possibleCallInstances>");
    println("        Project possible package-private call instance count:   <result.project_packagePrivateCallInstances>");
    println("        Project possible cross package-private call instances:  <result.project_crossPackage_packagePrivateCallInstances>");
    println("        Total package-private class count:                      <result.total_packagePrivateClassCount>");
    println("        Total pure package-private class count:                 <result.total_purePackagePrivateClassCount>");
    println("        Total instantiated pure package-private class count:    <result.total_instantiatedPurePackagePrivateClasses>");
    println("        Total package-private method count:                     <result.total_packagePrivateMethodCount>");

    str line = "<library.id>;<library.organisation>;<library.name>;<library.revision>;"
        + "<result.project_classCount>;<result.project_packagePrivateClassCount>;<result.project_purePackagePrivateClassCount>;<result.project_packagePrivateMethodCount>;"
        + "<result.project_totalMethodInvocationCount>;<result.project_unresolveableMethodInvocationCount>;<result.project_constructorInvocationCount>;<result.project_privateMethodInvocationCount>;"
        + "<result.project_staticMethodInvocationCount>;<result.project_monomorphicVirtualMethodInvocationCount>;<result.project_virtualMethodInvocationCount>;"
        + "<result.project_possibleCallInstances>;<result.project_packagePrivateCallInstances>;<result.project_crossPackage_packagePrivateCallInstances>;"
        + "<result.total_packagePrivateClassCount>;<result.total_purePackagePrivateClassCount>;<result.total_instantiatedPurePackagePrivateClasses>;<result.total_packagePrivateMethodCount>\r\n";
    appendToFile(packagePrivateFile, line);

    println("");
    println("    Library running time: <formatDuration(now() - startTime)>");
    println("------------------------------------------------------------------------");
}

public AnalysisResult getPrivatePackegeInvocations(M3 model, M3 completeModel) 
{
    rel[loc override, loc base] methodOverrides = { <override,base> | <override,base> <- completeModel.methodOverrides, !isConstructor(base) && base.scheme != "java+initializer" };

    set[loc] declaredMethods = { method | <method,_> <- completeModel.declarations, isMethod(method) };
    // The set of methods that are overriden at least once.
    set[loc] overridenMethods = range(completeModel.methodOverrides);
    // The set of static methods.
    set[loc] staticMethods = { method | <method,modifier> <- completeModel.modifiers, isMethod(method) && modifier == \static() };
    // The set of private instance methods (These can also be staticly resolved).
    set[loc] privateMethods = { method | <method,modifier> <- completeModel.modifiers,         isMethod(method) && !isConstructor(method) && modifier == \private() && method notin staticMethods };

    set[loc] methodInvocationSources = domain(model.methodInvocation);

    rel[loc from, loc to] methodInvocations = { <from,to> | <from,to> <- completeModel.methodInvocation, from in methodInvocationSources }; 
    rel[loc from, loc to] invalidMethodInvocations = { <from,to> | <from,to> <- methodInvocations, to notin declaredMethods };
    rel[loc from, loc to] validMethodInvocations = methodInvocations - invalidMethodInvocations;

    // Some statiscal numbers.    
    int project_unresolveableMethodInvocationCount = size(invalidMethodInvocations);
    int project_constructorInvocationCount = size( { <from,to> | <from,to> <- validMethodInvocations, isConstructor(to) } );
    int project_privateMethodInvocationCount = size( { <from,to> | <from,to> <- validMethodInvocations, to in privateMethods } );
    int project_staticMethodInvocationCount = size( { <from,to> | <from,to> <- validMethodInvocations, to in staticMethods } );
    int project_monomorphicVirtualMethodInvocationCount = size({ <from,to> | <from,to> <- validMethodInvocations,  to notin overridenMethods && !isConstructor(to) && to notin privateMethods && to notin staticMethods });

    // First, select invocations of methods that can not be resolved by CHA. These include
    // - Invocations of methods that are overriden by at least one other method.
    // - And are non-static, non-private and no constructors.  
    rel[loc,loc] virtualMethodInvocations = { <from,to> | <from,to> <- validMethodInvocations,  to in overridenMethods && !isConstructor(to) && to notin privateMethods && to notin staticMethods };

    // Determine the set of package-private classes.
    set[loc] totalPackagePrivateClasses = { class | class <- classes(completeModel) + enums(completeModel), <class,\public()> notin completeModel.modifiers && <class,\protected()> notin completeModel.modifiers && <class,\private()> notin completeModel.modifiers };
    set[loc] projectPackagePrivateClasses = { class | class <- classes(model) + enums(model), <class,\public()> notin model.modifiers && <class,\protected()> notin model.modifiers && <class,\private()> notin model.modifiers };
    
    // Determine the set of pure package-private classes. These are package-private classes that are not subclassed by any public class.
    set[loc] totalPurePackagePrivateClasses = totalPackagePrivateClasses - { super | <sub,super> <- completeModel.extends+, <sub,\public()> in completeModel.modifiers && super in totalPackagePrivateClasses };
    set[loc] projectPurePackagePrivateClasses = projectPackagePrivateClasses - { super | <sub,super> <- model.extends+, <sub,\public()> in model.modifiers && super in projectPackagePrivateClasses };

    // Determine the set of pure package-private classes.
    set[loc] totalLivePackagePrivateClasses = { classOf(to) | <from,to> <- completeModel.methodInvocation, isConstructor(to) && classOf(to) in totalPurePackagePrivateClasses };
    set[loc] projectLivePackagePrivateClasses = { classOf(to) | <from,to> <- completeModel.methodInvocation, isConstructor(to) && classOf(to) in projectPurePackagePrivateClasses };
    
    // Determine the set of methods that belong to a live pure package-private class.
    set[loc] projectPackagePrivateMethods = { method | <class,method> <- model.containment, class in totalLivePackagePrivateClasses && isMethod(method) };
    set[loc] totalPackagePrivateMethods = { method | <class,method> <- completeModel.containment, class in totalLivePackagePrivateClasses && isMethod(method) };
    
    

    // Create a mapping relation from method to package.
    rel[loc,loc] outerPackages = completeModel.containment - { <x,y> | <x,y> <- completeModel.containment, isPackage(x) && isPackage(y) };
    map[loc method, loc package] methodPackages = ( y : x | <x,y> <- outerPackages+, isPackage(x) && isMethod(y) );
    
    // Determine the set of all possible call instances for any given virtual method invocation.
    rel[loc base, loc override] transitiveOverrides = invert(methodOverrides+);
    possibleMethodInvocations = { <from,override> | <from,override> <- (virtualMethodInvocations o transitiveOverrides) };
    
    // Filter the set for invocations of methods belonging to package-private classes.
    possiblePackagePrivateMethodInvocations = { <from,override> | <from,override> <- possibleMethodInvocations, override in totalPackagePrivateMethods }; 
    
    // Finally, we filter the set for invocations for which the source method resides in a different package than the method which it invokes.
    crossPackageInvocations = { <from,override> | <from,override> <- possiblePackagePrivateMethodInvocations, methodPackages[from] != methodPackages[override] }; 
    
    return <
        model.id,                                           // modelId,
        size(classes(model) + enums(model)),                // project_classCount
        size(projectPackagePrivateClasses),                 // project_packagePrivateClassCount
        size(projectPurePackagePrivateClasses),             // project_purePackagePrivateClassCount,
        size(projectPackagePrivateMethods),                 // project_packagePrivateMethodCount
        size(methodInvocations),                            // project_totalMethodInvocationCount
        project_unresolveableMethodInvocationCount,         // project_unresolveableMethodInvocationCount
        project_constructorInvocationCount,                 // project_constructorInvocationCount
        project_privateMethodInvocationCount,               // project_privateMethodInvocationCount
        project_staticMethodInvocationCount,                // project_staticMethodInvocationCount,
        project_monomorphicVirtualMethodInvocationCount,    // project_monomorphicVirtualMethodInvocations
        size(virtualMethodInvocations),                     // project_virtualMethodInvocationCount,
        size(possibleMethodInvocations),                    // project_possibleCallInstances,
        size(possiblePackagePrivateMethodInvocations),      // project_packagePrivateCallInstances,
        size(crossPackageInvocations),                      // project_crossPackage_packagePrivateCallInstances
        size(totalPackagePrivateClasses),                   // total_packagePrivateClassCount,
        size(totalPurePackagePrivateClasses),               // total_purePackagePrivateClassCount,
        size(totalLivePackagePrivateClasses),               // total_instantiatedPurePackagePrivateClasses
        size(totalPackagePrivateMethods)                    // total_packagePrivateMethodCount
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




