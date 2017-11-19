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

public rel[loc,loc] UncorrectedInvocations = {};


public M3 repairM3For1145(M3 model) 
{
    // Find the incorrect clone invocations
    rel[loc,loc] cloneInvocations = { <source,target> | <source,target> <- model.methodInvocation, startsWith(target.path, "/[") && contains(target.path, "clone") };
    
    model.methodInvocation = model.methodInvocation - cloneInvocations + { <from,|java+method:///java/lang/Object/clone()|> | <from,_> <- cloneInvocations };

    println("Found and corrected <size(cloneInvocations)>");

    return model;
}


public M3 repairM3For1129(M3 model) 
{
    startTime = now();
    
    set[loc] declaredMethods = methods(model);
    set[loc] declaredClasses = classes(model);
    set[loc] declaredEnums = enums(model);
    set[loc] declaredInterfaces = interfaces(model);

    // Incorrect invocations are invocations for which the target does not exist in the 'declarations' relation.
    rel[loc,loc] incorrectInvocations = { <source,target> | <source,target> <- model.methodInvocation, target notin declaredMethods };

    int totalOriginalMethodInvocations = size(model.methodInvocation);
    int totalIncorrectMethodInvocations = size(incorrectInvocations);

    rel[loc,loc] correctedInvocations = {};
    
    invocationsToCorrectClass = { <from,to,classOf(to)> | <from,to> <- incorrectInvocations, classOf(to) in declaredClasses };
    invocationsToCorrectEnum = { <from,to,enumOf(to)> | <from,to> <- incorrectInvocations, enumOf(to) in declaredEnums };
    invocationsToCorrectInterface = { <from,to,interfaceOf(to)> | <from,to> <- incorrectInvocations, interfaceOf(to) in declaredInterfaces };
    
    uncorrectedInvocations = { <from,to> | <from,to> <- incorrectInvocations, classOf(to) notin declaredClasses && enumOf(to) notin declaredEnums && interfaceOf(to) notin declaredInterfaces };
    
    map[loc,loc] declaredClassHierarchy = getDeclaredClassHierarchy(model);
    
    //
    // First pass.
    //
    int j = 0;
    
    // If the declared type was a class, the method must exist on one of its parent classes.
    // There is an exception to this involving abstract classes. In that case the compiled abstract class 
    while(size(invocationsToCorrectClass) > 0 && j < 10) 
    {
        tempSet = { <from,to,declaredClassHierarchy[class]> | <from,to,class> <- invocationsToCorrectClass };

        newMethods = { <from,to,class,toLocation(to.scheme + "://" + class.path) + to.file> | <from,to,class> <- tempSet };
        
        correctMethods = { <from,newTo> | <from,_,_,newTo> <- newMethods, newTo in declaredMethods };
        
        correctedInvocations += correctMethods;
        invocationsToCorrectClass = { <from,to,class> | <from,to,class,newTo> <- newMethods, newTo notin declaredMethods };
        
        j += 1;
    }
    
    // Reset the remaining 
    invocationsToCorrectClass = { <from,to,classOf(to)> | <from,to,_> <- invocationsToCorrectClass };
    
    declaredEnumHierarchy = getDeclaredEnumHierarchy(model);
    
    // Do enums
    j = 0;
    while(size(invocationsToCorrectEnum) > 0 && j < 10) 
    {
        tempSet = { <from,to,declaredEnumHierarchy[enum]> | <from,to,enum> <- invocationsToCorrectEnum };

        newMethods = { <from,to,enum,toLocation(to.scheme + "://" + enum.path) + to.file> | <from,to,enum> <- tempSet };
        
        correctMethods = { <from,newTo> | <from,_,_,newTo> <- newMethods, newTo in declaredMethods };
        
        correctedInvocations += correctMethods;
        invocationsToCorrectEnum = { <from,to,enum> | <from,to,enum,newTo> <- newMethods, newTo notin declaredMethods };
        
        j += 1;
    }
    // Reset the remaining 
    invocationsToCorrectEnum = { <from,to,enumOf(to)> | <from,to,_> <- invocationsToCorrectEnum };
    
       
    // Do interfaces
    declaredInterfaceHierarchy = { <from,to> | <from,to> <- model.implements, isInterface(from) };
    
    j = 0;

    while(size(invocationsToCorrectInterface) > 0 && j < 10) 
    {
        tempSet = { <from,to,superInterfaceOf(class, declaredInterfaceHierarchy)> | <from,to,class> <- invocationsToCorrectInterface };

        newMethods = { <from,to,class,toLocation(to.scheme + "://" + class.path) + to.file> | <from,to,class> <- tempSet };
        
        correctMethods = { <from,newTo> | <from,_,_,newTo> <- newMethods, newTo in declaredMethods };
        
        correctedInvocations += correctMethods;
        invocationsToCorrectInterface = { <from,to,class> | <from,to,class,newTo> <- newMethods, newTo notin declaredMethods };
        
        j += 1;
    }
    // Reset the remaining 
    invocationsToCorrectInterface = { <from,to,interfaceOf(to)> | <from,to,_> <- invocationsToCorrectInterface };


    //
    // Second pass.
    //

    declaredTypeHierarchy = getDeclaredTypeHierarchy(model);
    
    rel[loc from,loc to, loc declaredType] invocationsToCorrect = invocationsToCorrectClass + invocationsToCorrectInterface + invocationsToCorrectEnum;
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
                    methodFound = true;
                }
            }
        }
        if(!methodFound) 
        {
            uncorrectedInvocations += <invocation.from, invocation.to>;
        }
    } 
    
    // Correct invocations are invocations for which the target does exist in the 'declarations' relation.
    rel[loc,loc] correctInvocations = { <source,target> | <source,target> <- model.methodInvocation, target in declaredMethods };
    

    model.methodInvocation = correctInvocations + uncorrectedInvocations + correctedInvocations;
    
    UncorrectedInvocations = uncorrectedInvocations;
    
    println("   Total method invocations:              <size(model.methodInvocation)>");
    println("   Total method invocations prior to fix: <totalOriginalMethodInvocations>");
    println("   Total correct method invocations:      <size(correctInvocations)>");
    println("   Total corrected method invocations:    <size(correctedInvocations)>");
    println("   Total uncorrected method invocations:  <size(uncorrectedInvocations)>");
    
    println("   Run time: <formatDuration(now() - startTime)>");
   
    return model;
}

public loc classOf(loc method) = |java+class:///| + method.parent.path;
public loc interfaceOf(loc method) = |java+interface:///| + method.parent.path;
public loc enumOf(loc method) = |java+enum:///| + method.parent.path;

public loc superInterfaceOf(loc class, rel[loc,loc] extends) 
{
    set[loc] superClass = extends[class];
    
    if(!isEmpty(superClass)) {
        return getOneFrom(superClass);
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
