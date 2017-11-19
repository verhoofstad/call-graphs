module main::analysis::Util

import Prelude;
import lang::java::m3::Core;
import main::DateTime;
import main::Util;
import main::analysis::DataSet;

// Environmental settings
public loc libraryFolder = |file:///C:/CallGraphData/Libraries|;
public loc jdkFolder = |file:///C:/CallGraphData/JavaJDK/java-8-openjdk-amd64|;


public M3 loadLib(int libraryId) 
{
    return loadLib(libraryId, false);
} 

public M3 loadLib(int libraryId, bool incLibraries) 
{
    loc projectJar = libraryFolder + TestDataSet[libraryId].cpFile;
    M3 model = createM3FromJar(projectJar);

    if(incLibraries) 
    {
        set[M3] libModels = { createM3FromJar(libraryFolder + libFile) | libFile <- TestDataSet[libraryId].libFiles };
    
        return composeM3(projectJar, { model } + libModels );        
    }
    return model; 
}

public M3 loadJDK() 
{
    startTime = now();
    println("Loading Java JDK Libraries...");
    
    set[M3] jdkModels = {};
    
    for(loc jar <- findJars(jdkFolder)) 
    {
        print("   Loading <replaceAll(jar.path, jdkFolder.path, "")>...");
        jdkModels += createM3FromJar(jar);
        println("Ok");
    }
    println("Loading Java JDK Libraries complete (Time <formatDuration(now() - startTime)>)");
    return composeM3(jdkFolder, jdkModels);
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
