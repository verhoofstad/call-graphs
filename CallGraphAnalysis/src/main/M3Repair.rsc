module main::M3Repair

import Prelude;
import lang::java::m3::Core;
import lang::java::m3::AST;
import lang::java::m3::TypeHierarchy;
import lang::java::jdt::m3::Core;
import analysis::graphs::Graph;

import main::Util;
import main::DateTime;
import main::analysis::DataSet;
import main::analysis::Util;

public M3 repairM3For1128(M3 model) 
{
    declaredMethod = { <toLocation(replaceAll(m.uri, "$", "/")), m> | m <- methods(model) };

    unDeclaredMethod = { <m, toLocation(replaceAll(m.uri, "$", "/"))> | m <- carrier(model.methodInvocation)  };

    correctionMap = unDeclaredMethod o declaredMethod;

    uncorrectableMethods = carrier(model.methodInvocation) - domain(correctionMap);
    correctionMap += { <old,old> | old <- uncorrectableMethods };

    // Correct the domain of the methodInvocarion relation.        
    model.methodInvocation = invert(correctionMap) o  model.methodInvocation;
    // Correct the range of the methodInvocarion relation.
    model.methodInvocation = model.methodInvocation o correctionMap;
  
    return model;
}

public rel[loc,loc] UncorrectedInvocations = {};

public M3 repairM3(M3 model) 
{
    return repairM3For1129(repairM3For1145(model));
}


public M3 repairM3For1145(M3 model) 
{
    // Find the incorrect clone invocations
    rel[loc,loc] cloneInvocations = { <source,target> | <source,target> <- model.methodInvocation, startsWith(target.path, "/[") && contains(target.path, "clone") };
    
    model.methodInvocation = model.methodInvocation - cloneInvocations + { <from,|java+method:///java/lang/Object/clone()|> | <from,_> <- cloneInvocations };

    println("        Found and corrected <size(cloneInvocations)>");

    return model;
}

// Some public variables for post-repair manual inspection.
public rel[loc,loc] IncorrectInvocations = {};
public rel[loc,loc] UnknownDeclaredType = {};

public M3 loadAndRepairLib(int libraryId, M3 jdkModel) 
{
    print("Loading library...");
    M3 model = loadLib(libraryId, true, jdkModel);
    println("Ok");

    set[loc] declaredMethods = methods(model);
    set[loc] declaredClasses = classes(model);
    set[loc] declaredEnums = enums(model);
    set[loc] declaredInterfaces = interfaces(model);
    
    rel[loc,loc] correctInvocations = { <source,target> | <source,target> <- model.methodInvocation, target in declaredMethods };
    
    // Incorrect invocations are invocations for which the target does not exist in the 'declarations' relation.
    IncorrectInvocations = model.methodInvocation - correctInvocations;
    
    UnknownDeclaredType = { <from,to> | <from,to> <- IncorrectInvocations, classOf(to) notin declaredClasses && enumOf(to) notin declaredEnums && interfaceOf(to) notin declaredInterfaces };
    
    return model;
}


public M3 repairM3For1129(M3 model) 
{
    startTime = now();

    println("        Total method invocations:              <size(model.methodInvocation)>");
    
    set[loc] declaredMethods = methods(model);
    set[loc] declaredClasses = classes(model);
    set[loc] declaredEnums = enums(model);
    set[loc] declaredInterfaces = interfaces(model);

    // Correct invocations are invocations for which the target does exist in the 'declarations' relation.
    rel[loc source, loc target] correctInvocations = { <source,target> | <source,target> <- model.methodInvocation, target in declaredMethods };

    // Incorrect invocations are invocations for which the target does not exist in the 'declarations' relation.
    rel[loc source, loc target] incorrectInvocations = model.methodInvocation - correctInvocations;
    
    println("        Total correct method invocations:      <size(correctInvocations)>");
    println("        Total incorrect method invocations:    <size(incorrectInvocations)>");

    rel[loc source, loc target, loc class] invocationsToCorrectClass = { <source, target, classOf(target)> | <source,target> <- incorrectInvocations, classOf(target) in declaredClasses };
    rel[loc source, loc target, loc enum] invocationsToCorrectEnum = { <source, target, enumOf(target)> | <source,target> <- incorrectInvocations, enumOf(target) in declaredEnums };
    rel[loc source, loc target, loc interface] invocationsToCorrectInterface = { <source, target, interfaceOf(target)> | <source,target> <- incorrectInvocations, interfaceOf(target) in declaredInterfaces };
    rel[loc source, loc target] uncorrectedInvocations = { <source,target> | <source,target> <- incorrectInvocations, 
        classOf(target) notin declaredClasses && enumOf(target) notin declaredEnums && interfaceOf(target) notin declaredInterfaces };

    println("          - declared type is class:            <size(invocationsToCorrectClass)>");
    println("          - declared type is enum:             <size(invocationsToCorrectEnum)>");
    println("          - declared type is interface:        <size(invocationsToCorrectInterface)>");
    println("          - declared type is unknown:          <size(uncorrectedInvocations)>");

    rel[loc,loc] correctedInvocations = {};
    
    UnknownDeclaredType = uncorrectedInvocations;
    
    //
    // First pass. (Fast)
    //
    map[loc sub, loc super] classHierarchy = getDeclaredClassHierarchy(model);
    int j = 0;
    
    // If the declared type was a class, the method must exist on one of its parent classes.
    // There is an exception to this involving abstract classes.
    while(size(invocationsToCorrectClass) > 0 && j < 10) 
    {
        //tempSet = { <from,to,declaredClassHierarchy[class]> | <from,to,class> <- invocationsToCorrectClass };
        //newMethods = { <from,to,class,toLocation(to.scheme + "://" + class.path) + to.file> | <from,to,class> <- tempSet };

        newMethods = { <source, target, classHierarchy[class], toLocation(target.scheme + "://" + classHierarchy[class].path) + target.file> | <source,target,class> <- invocationsToCorrectClass };
        
        correctMethods = { <source, newTarget> | <source,_,_,newTarget> <- newMethods, newTarget in declaredMethods };
        
        correctedInvocations += correctMethods;
        invocationsToCorrectClass = { <source,target,class> | <source,target,class,newTarget> <- newMethods, newTarget notin declaredMethods };
        
        j += 1;
    }
    
    // Reset the remaining for the seccond pass.
    invocationsToCorrectClass = { <from,to,classOf(to)> | <from,to,_> <- invocationsToCorrectClass };
    println("        Incorrect class invocations remaining after 1st pass:     <size(invocationsToCorrectClass)>");
    
    
    // Do enums
    map[loc sub, loc super] enumHierarchy = getDeclaredEnumHierarchy(model);

    j = 0;
    while(size(invocationsToCorrectEnum) > 0 && j < 10) 
    {
        //tempSet = { <from,to,declaredEnumHierarchy[enum]> | <from,to,enum> <- invocationsToCorrectEnum };
        //newMethods = { <from,to,enum,toLocation(to.scheme + "://" + enum.path) + to.file> | <from,to,enum> <- tempSet };

        newMethods = { <source, target, enumHierarchy[enum], toLocation(target.scheme + "://" + enumHierarchy[enum].path) + target.file> | <source, target, enum> <- invocationsToCorrectEnum };
        
        correctMethods = { <source, newTarget> | <source,_,_,newTarget> <- newMethods, newTarget in declaredMethods };
        
        correctedInvocations += correctMethods;
        invocationsToCorrectEnum = { <source,target,enum> | <source,target,enum,newTarget> <- newMethods, newTarget notin declaredMethods };
        
        j += 1;
    }
    // Reset the remaining 
    invocationsToCorrectEnum = { <source, target, enumOf(target)> | <source, target,_> <- invocationsToCorrectEnum };
    println("        Incorrect enum invocations remaining after 1st pass:      <size(invocationsToCorrectEnum)>");
    
       
    // Do interfaces
    // No map here due to multiple inheritance of interfaces.
    rel[loc sub, loc super] interfaceHierarchy = { <sub, super> | <sub, super> <- model.implements, isInterface(sub) };
    
    j = 0;

    while(size(invocationsToCorrectInterface) > 0 && j < 10) 
    {
        tempSet = { <source, target, superInterfaceOf(class, interfaceHierarchy)> | <source,target,class> <- invocationsToCorrectInterface };
        newMethods = { <source, target, interface, toLocation(target.scheme + "://" + interface.path) + target.file> | <source, target, interface> <- tempSet };

        correctMethods = { <source, newTarget> | <source,_,_,newTarget> <- newMethods, newTarget in declaredMethods };
        
        correctedInvocations += correctMethods;
        invocationsToCorrectInterface = { <source, target, interface> | <source, target, interface, newTarget> <- newMethods, newTarget notin declaredMethods };
        
        j += 1;
    }
    // Reset the remaining 
    invocationsToCorrectInterface = { <source, target, interfaceOf(target)> | <source, target, _> <- invocationsToCorrectInterface };
    println("        Incorrect interface invocations remaining after 1st pass: <size(invocationsToCorrectInterface)>");


    //
    // Second pass. (More precise but also much slower)
    //

    declaredTypeHierarchy = getDeclaredTypeHierarchy(model);
    
    rel[loc source, loc target, loc declaredType] invocationsToCorrect = invocationsToCorrectClass + invocationsToCorrectInterface + invocationsToCorrectEnum;

    // Sort the declared type hierarchy topologically.    
    list[loc] sortedTypeHierarchy = order(declaredTypeHierarchy);
    
    for(invocation <- invocationsToCorrect) 
    {
        // Get all supertypes (classes, interfaces) for the current type in their toplogical order.
        // This works only assuming the order remains intact after the intersect operation.
        superTypes = sortedTypeHierarchy & toList(reach(declaredTypeHierarchy, { invocation.declaredType }));
       
        bool methodFound = false;
        for(superType <- superTypes) 
        {
            if(!methodFound)
            {
                loc method = toLocation(invocation.target.scheme + "://" + superType.path) + invocation.target.file;
                
                if(method in declaredMethods) 
                {
                    correctedInvocations += <invocation.source, method>;
                    methodFound = true;
                }
            }
        }
        if(!methodFound) 
        {
            uncorrectedInvocations += <invocation.source, invocation.target>;
        }
    } 
    
    model.methodInvocation = correctInvocations + uncorrectedInvocations + correctedInvocations;
    
    UncorrectedInvocations = uncorrectedInvocations;
    
    println("        Total corrected method invocations:    <size(correctedInvocations)>");
    println("        Total uncorrected method invocations:  <size(uncorrectedInvocations)>");
    
    println("        Run time: <formatDuration(now() - startTime)>");
   
    return model;
}

public loc classOf(loc method) = |java+class:///| + method.parent.path;
public loc interfaceOf(loc method) = |java+interface:///| + method.parent.path;
public loc enumOf(loc method) = |java+enum:///| + method.parent.path;

public loc superInterfaceOf(loc class, rel[loc,loc] extends) 
{
    set[loc] superInterfaces = extends[class];
    
    if(!isEmpty(superInterfaces)) {
        // Just pick one...
        return getOneFrom(superInterfaces);
    } else{
        return class;
    }
}


public void validateM3(M3 model) 
{
    set[loc]  notDeclared = {};
    
    notDeclared = carrier(model.methodInvocation) - domain(model.declarations);
    println("    Undeclared method invocations: <size(notDeclared)>");
    
    //notDeclaredStr = { replaceAll(m.uri, "$", "/") | m <- carrier(model.methodInvocation) } - { replaceAll(m.uri, "$", "/" ) | m <- domain(model.declarations) };
    //println("    Undeclared method invocations when ignoring $ sign: <size(notDeclaredStr)>");
    
    notDeclared = domain(model.modifiers) - domain(model.declarations);
    println("    Undeclared element in modifiers: <size(notDeclared)>");
    
    notDeclared = carrier(model.extends) - domain(model.declarations);
    println("    Undeclared extends:            <size(notDeclared)>");
    
    notDeclared = carrier(model.implements) - domain(model.declarations);
    println("    Undeclared implements:         <size(notDeclared)>");
}


public void validateM3(list[int] libraryIdentifiers, M3 jdkModel) 
{

    for(library <- TestDataSet, library.id in libraryIdentifiers) 
    {
        list[loc] jarFiles = [ libraryFolder + library.cpFile ] + [ libraryFolder + libFile | libFile <- library.libFiles, libFile != "java-8-openjdk-amd64/jre/lib/" ]; 
            
        M3 model = composeM3(|project://complete|, { createM3FromJars(libraryFolder + library.cpFile, jarFiles), jdkModel } );
    
        notDeclared = carrier(model.extends) - domain(model.declarations);
        
        typeHierarhy = getDeclaredTypeHierarchy(model);
        notInTypeHierarchy =  classes(model) + interfaces(model) - domain(typeHierarhy);
        
        classHierarchy = getDeclaredClassHierarchy(model);
        notInClassHierarchy =  classes(model) - domain(classHierarchy);
        
        println("    <right("<library.id>", 2, " ")> <left(library.cpFile, 70, " ")>:  <right("<size(notDeclared)>", 3, " ")>    <right("<size(notInTypeHierarchy)>", 5, " ")>    <right("<size(notInClassHierarchy)>", 5, " ")>");
  
    }
}
