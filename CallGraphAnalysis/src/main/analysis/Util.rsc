module main::analysis::Util

import Prelude;
import lang::java::m3::Core;
import main::DateTime;
import main::Util;
import main::analysis::DataSet;
import analysis::m3::Core;

// Environmental settings
public loc libraryFolder = |file:///C:/CallGraphData/Libraries|;
public loc jdkFolder = |file:///C:/CallGraphData/JavaJDK/java-8-openjdk-amd64|;


public M3 loadLib(int libraryId) 
{
    return loadLib(libraryId, false);
} 

public M3 loadLib(int libraryId, bool incLibraries) 
{
    return loadLib(libraryId, incLibraries, emptyM3(|project://empty|)); 
}

public M3 loadLib(int libraryId, bool incLibraries, M3 jdkModel) 
{
    loc projectJar = libraryFolder + CompleteDataSet()[libraryId].cpFile;
    M3 model = createM3FromJar(projectJar);

    if(incLibraries) 
    {
        set[M3] libModels = { createM3FromJar(libraryFolder + libFile) | libFile <- CompleteDataSet()[libraryId].libFiles, libFile != "java-8-openjdk-amd64/jre/lib/" };
    
        return composeM3(projectJar, { model } + libModels + { jdkModel } );        
    }
    return model; 
}

public void validateLib(list[Library] libraries) 
{
    for(library <- libraries) 
    {
        validateLib(library);
    }
}

public void validateLib(Library library) 
{
    for(libFile <- library.libFiles + [library.cpFile]) 
    {
        loc jarFile = libraryFolder + libFile;
    
        if(!exists(jarFile)) 
        {
            println("Error in lib <library.id>: File <jarFile> does not exists.");            
        }
    }
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
