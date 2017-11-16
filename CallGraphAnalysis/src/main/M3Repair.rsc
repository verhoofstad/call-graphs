module main::M3Repair

import Prelude;
import lang::java::m3::Core;
import lang::java::m3::AST;
import lang::java::m3::TypeHierarchy;
import lang::java::jdt::m3::Core;
import analysis::graphs::Graph;

import main::Util;
import main::DateTime;

public M3 repairM3(M3 model) 
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

public rel[loc,loc] ExternalInvocations = {};
public rel[loc,loc,loc] UncorrectableInvocationsOnClases = {};

public rel[loc,loc] UncorrectedInFirstPass = {};
public rel[loc,loc,loc] CorrectedInSecondPass = {};

public M3 repairM3For1129(M3 model) 
{
    startTime = now();

    set[loc] declaredMethods = { m | m <- domain(model.declarations), isMethod(m) || m.scheme == "java+initializer" };
    set[loc] declaredClasses = { c | c <- domain(model.declarations), isClass(c) };
    set[loc] declaredInterfaces = { i | i <- domain(model.declarations), isInterface(i) };

    int totalOriginalMethodInvocations = size(model.methodInvocation);

    // Correct invocations are invocations for which the target does exist in the 'declarations' relation.
    rel[loc,loc] correctInvocations = { <source,target> | <source,target> <- model.methodInvocation, target in declaredMethods };
    
    // Incorrect invocations are invocations for which the target does not exist in the 'declarations' relation.
    rel[loc,loc] incorrectInvocations = { <source,target> | <source,target> <- model.methodInvocation, target notin declaredMethods };

    // Incorrect invocations can be divided in two sub sets:
    rel[loc,loc] externalInvocations = { <source,target> | <source,target> <- incorrectInvocations, classOf(target) notin declaredClasses && interfaceOf(target) notin declaredInterfaces };
    
    rel[loc,loc] correctedInvocations = {};
    rel[loc,loc] uncorrectedInvocations = {};

    invocationsToCorrectClass = { <from,to,classOf(to)> | <from,to> <- incorrectInvocations - externalInvocations, classOf(to) in declaredClasses };
    invocationsToCorrectInterface = { <from,to,interfaceOf(to)> | <from,to> <- incorrectInvocations - externalInvocations, interfaceOf(to) in declaredInterfaces };
    
    declaredClassHierarchy = getDeclaredClassHierarchy(model);
    
    //
    // First pass.
    //
    int j = 0;

    // If the declared type was a class, the method must exist on one of its parent classes.
    while(size(invocationsToCorrectClass) > 0 && j < 10) 
    {
        tempSet = { <from,to,superClassOf(class, declaredClassHierarchy)> | <from,to,class> <- invocationsToCorrectClass };

        newMethods = { <from,to,class,toLocation(to.scheme + "://" + class.path) + to.file> | <from,to,class> <- tempSet };
        
        correctMethods = { <from,newTo> | <from,_,_,newTo> <- newMethods, newTo in declaredMethods };
        
        correctedInvocations += correctMethods;
        invocationsToCorrectClass = { <from,to,class> | <from,to,class,newTo> <- newMethods, newTo notin declaredMethods };
        
        println("<size(correctMethods)> methods corrected; <size(invocationsToCorrectClass)> remaining.");
        j += 1;
    }
    
   
    // Do interfaces
    println("Total interface invocations to correct: <size(invocationsToCorrectInterface)>");
    
    declaredInterfaceHierarchy = { <from,to> | <from,to> <- model.implements, isInterface(from) };
    
    j = 0;

    while(size(invocationsToCorrectInterface) > 0 && j < 10) 
    {
        tempSet = { <from,to,superInterfaceOf(class, declaredInterfaceHierarchy)> | <from,to,class> <- invocationsToCorrectInterface };

        newMethods = { <from,to,class,toLocation(to.scheme + "://" + class.path) + to.file> | <from,to,class> <- tempSet };
        
        correctMethods = { <from,newTo> | <from,_,_,newTo> <- newMethods, newTo in declaredMethods };
        
        correctedInvocations += correctMethods;
        invocationsToCorrectInterface = { <from,to,class> | <from,to,class,newTo> <- newMethods, newTo notin declaredMethods };
        
        println("<size(correctMethods)> methods corrected; <size(invocationsToCorrectInterface)> remaining.");
        j += 1;
    }


    println("Invocations to correct remaining: <size(invocationsToCorrectInterface)>");

    //
    // Second pass.
    //

    declaredTypeHierarchy = getDeclaredTypeHierarchy(model);
    // Remove entries where classes extend from themselves.
    declaredTypeHierarchy -= { <from,to> | <from,to> <- declaredTypeHierarchy, from == to };
    
    int i = 0;
    
    rel[loc from,loc to, loc declaredType] invocationsToCorrect = invocationsToCorrectClass + invocationsToCorrectInterface;

    println("Start correcting <size(invocationsToCorrect)> invocations...");
    
    list[loc] sortedTypeHierarchy = order(declaredTypeHierarchy);
    
    for(invocation <- invocationsToCorrect) 
    {
        superTypes = sortedTypeHierarchy & toList(reach(declaredTypeHierarchy, { invocation.declaredType }));
       
        bool methodFound = false;
        for(superType <- superTypes) 
        {
            if(!methodFound)
            {
                loc method = toLocation(invocation.to.scheme + "://" + superType.path) + invocation.to.file;
                
                if(method in declaredMethods) 
                {
                    correctedInvocations += <invocation.from, method>;
                    
                    CorrectedInSecondPass += <invocation.from, invocation.to, method>;
                    
                    
                    methodFound = true;
                }
            }
        }
        if(!methodFound) 
        {
            uncorrectedInvocations += <invocation.from, invocation.to>;
        }
        i += 1;
        if(i mod 250 == 0) {
            println("Done <i>");
            println("So far corrected: <size(correctedInvocations)>");
            println("So far uncorrected: <size(uncorrectedInvocations)>");
        }
    } 

    model.methodInvocation = correctInvocations + externalInvocations + uncorrectedInvocations + correctedInvocations;
    
    
    println("Total method invocations:              <size(model.methodInvocation)>");
    println("Total method invocations prior to fix: <totalOriginalMethodInvocations>");
    println("Total correct method invocations:      <size(correctInvocations)>");
    println("Total external method invocations:     <size(externalInvocations)>");
    println("Total corrected method invocations:    <size(correctedInvocations)>");
    println("Total uncorrected method invocations:  <size(uncorrectedInvocations)>");
    
    println("Run time: <formatDuration(now() - startTime)>");
    
    
    return model;
}

public loc classOf(loc method) = |java+class:///| + method.parent.path;
public loc interfaceOf(loc method) = |java+interface:///| + method.parent.path;
public loc superClassOf(loc class, rel[loc,loc] declaredClassHierarchy) 
{
    set[loc] superClass = declaredClassHierarchy[class];
    
    if(!isEmpty(superClass)) {
        return getOneFrom(superClass);
    } else{
        return class;
    }
}

public loc superInterfaceOf(loc class, rel[loc,loc] extends) 
{
    set[loc] superClass = extends[class];
    
    if(!isEmpty(superClass)) {
        return getOneFrom(superClass);
    } else{
        return class;
    }
}


public rel[loc,loc] superTypesOf(loc currentType, rel[loc,loc] declaredTypeHierarchy) 
{
    rel[loc,loc] superTypes =  { <from, c> | <from, c> <- declaredTypeHierarchy, from == currentType && isClass(c) }
        + { <from, i> | <from,i> <- declaredTypeHierarchy, from == currentType && isInterface(i) };
        
    return superTypes + ({} | it + superTypesOf(to, declaredTypeHierarchy) | <from,to> <- superTypes);
}  

public rel[loc,loc] testSuperClasses(loc declaredType, M3 model) 
{
    declaredTypeHierarchy = getDeclaredTypeHierarchy(model);
    transitiveDeclaredTypeHierarchy = declaredTypeHierarchy+; 
    
    //{ transitiveDeclaredTypeHierarchy
    
    return { <from,to> | <from,to> <- declaredTypeHierarchy, <declaredType, to> in declaredTypeHierarchy };
}




public void validateM3(M3 model) 
{
    set[loc]  notDeclared = {};
    
    notDeclared = carrier(model.methodInvocation) - domain(model.declarations);
    println("    Undeclared method invocations: <size(notDeclared)>");
    
    notDeclaredStr = { replaceAll(m.uri, "$", "/") | m <- carrier(model.methodInvocation) } - { replaceAll(m.uri, "$", "/" ) | m <- domain(model.declarations) };
    println("    Undeclared method invocations when ignoring $ sign: <size(notDeclaredStr)>");
    
    notDeclared = domain(model.modifiers) - domain(model.declarations);
    println("    Undeclared element in modifiers: <size(notDeclared)>");
    
    notDeclared = carrier(model.extends) - domain(model.declarations);
    println("    Undeclared extends:            <size(notDeclared)>");
    
    notDeclared = carrier(model.implements) - domain(model.declarations);
    println("    Undeclared implements:         <size(notDeclared)>");
}
