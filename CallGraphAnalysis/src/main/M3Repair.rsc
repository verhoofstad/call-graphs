module main::M3Repair

import Prelude;
import lang::java::m3::Core;
import lang::java::m3::AST;
import lang::java::m3::TypeHierarchy;
import lang::java::jdt::m3::Core;
import analysis::graphs::Graph;

import main::Util;

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



public M3 repairM3For1129(M3 model) 
{
    set[loc] declaredMethods = { m | m <- domain(model.declarations), isMethod(m) || m.scheme == "java+initializer" };
    set[loc] declaredClasses = { c | c <- domain(model.declarations), isClass(c) };
    set[loc] declaredInterfaces = { i | i <- domain(model.declarations), isInterface(i) };

    println("Total method invocations:    <size(model.methodInvocation)>");

    // Correct invocations are invocations for which the target does exist in the 'declarations' relation.
    rel[loc,loc] correctInvocations = { <source,target> | <source,target> <- model.methodInvocation, target in declaredMethods };
    println("Total correct invocations:   <size(correctInvocations)>");
    
    // Incorrect invocations are invocations for which the target does not exist in the 'declarations' relation.
    rel[loc,loc] incorrectInvocations = { <source,target> | <source,target> <- model.methodInvocation, target notin declaredMethods };

    // Incorrect invocations can be divided in two sub sets:
    rel[loc,loc] externalInvocations = { <source,target> | <source,target> <- incorrectInvocations, classOf(target) notin declaredClasses && interfaceOf(target) notin declaredInterfaces };
    ExternalInvocations = externalInvocations;

    println("Total external invocations:  <size(externalInvocations)>");
    
    rel[loc from,loc to] invocationsToCorrect = incorrectInvocations - externalInvocations;

    println("Total invocations to correct: <size(invocationsToCorrect)>");

    rel[loc,loc] correctedInvocations = {};


    // Select set 

    invocationsToCorrectClass = { <from,to,classOf(to)> | <from,to> <- invocationsToCorrect, classOf(to) in declaredClasses };
    invocationsToCorrectInterface = { <from,to,interfaceOf(to)> | <from,to> <- invocationsToCorrect, interfaceOf(to) in declaredInterfaces };
    
    declaredClassHierarchy = getDeclaredClassHierarchy(model);
    
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
    
    UncorrectableInvocationsOnClases = invocationsToCorrectClass;
    
    println("Total interface invocations to correct: <size(invocationsToCorrectInterface)>");
    j = 0;

    while(size(invocationsToCorrectInterface) > 0 && j < 10) 
    {
        tempSet = { <from,to,superInterfaceOf(class, model.implements)> | <from,to,class> <- invocationsToCorrectInterface };

        newMethods = { <from,to,class,toLocation(to.scheme + "://" + class.path) + to.file> | <from,to,class> <- tempSet };
        
        correctMethods = { <from,newTo> | <from,_,_,newTo> <- newMethods, newTo in declaredMethods };
        
        correctedInvocations += correctMethods;
        invocationsToCorrectInterface = { <from,to,class> | <from,to,class,newTo> <- newMethods, newTo notin declaredMethods };
        
        println("<size(correctMethods)> methods corrected; <size(invocationsToCorrectInterface)> remaining.");
        j += 1;
    }

    invocationsToCorrect = { <from,to> | <from,to,_> <- invocationsToCorrectClass } + { <from,to> | <from,to,_> <- invocationsToCorrectInterface };

    println("Invocations to correct remaining: <size(invocationsToCorrect)>");

    declaredTypeHierarchy = getDeclaredTypeHierarchy(model);
    // Remove entries where classes extend from themselves.
    declaredTypeHierarchy -= { <from,to> | <from,to> <- declaredTypeHierarchy, from == to };
    
    rel[loc,loc] uncorrectedInvocations = {};
    
    println("Start correcting <size(invocationsToCorrect)> invocations...");
    int i = 0;
    
    for(invocation <- invocationsToCorrect) 
    {
        loc declaredClass = classOf(invocation.to);
        loc declaredInterface = interfaceOf(invocation.to);
        
        loc declaredType;
        
        if(declaredClass in declaredClasses)
        {
            declaredType = declaredClass;
        } 
        elseif(declaredInterface in declaredInterfaces) 
        {
            declaredType = declaredInterface;
        }
        else
        {
            println("Both <declaredClass> and <declaredInterface> do not exists.");
            uncorrectedInvocations += invocation;
            continue;
        }
        
        
        superTypes = superTypesOf(declaredType, declaredTypeHierarchy);
       
        bool methodFound = false;
        for(superType <- order(superTypes)) 
        {
            if(!methodFound)
            {
                loc method = toLocation(invocation.to.scheme + "://" + superType.path) + invocation.to.file;
                
                if(method in declaredMethods) 
                {
                    correctedInvocations += <invocation.from, method>;
                    methodFound = true;
                }
            }
        }
        if(!methodFound) 
        {
            uncorrectedInvocations += invocation;
        }
        i += 1;
        if(i mod 250 == 0) {
            println("Done <i>");
            println("So far corrected: <size(correctedInvocations)>");
            println("So far uncorrected: <size(uncorrectedInvocations)>");
        }
    } 

    model.methodInvocation = correctInvocations + externalInvocations + correctedInvocations;
    
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
    rel[loc,loc] superTypes = domainR( declaredTypeHierarchy, { currentType } );
    
    // { <from, c> | <from, c> <- declaredTypeHierarchy, from == currentType && isClass(c) }
    //    + { <from, i> | <from,i> <- declaredTypeHierarchy, from == currentType && isInterface(i) };
        
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
