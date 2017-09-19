module main::results::LoadResults

import main::results::ResultSet;
import Prelude;
import String;
import IO;


//public loc resultsFile = |file:///C:/Users/verho/OneDrive/Mijn%20documenten/Master%20Software%20Engineering/Master%20Thesis/Docker/results.txt|;
public loc resultsFile = |file:///C:/Users/Erik/OneDrive/Mijn%20documenten/Master%20Software%20Engineering/Master%20Thesis/Docker/results.txt|;

public result resultsOf(list[result] results, str organisation, str name, str revision) 
{
	return head([ result | result <- results, result.organisation == organisation && result.name == name && result.revision == revision ]);
}

public list[result] LoadResults(loc resultsFile) 
{
	if(!isFile(resultsFile)) throw "<resultsFile> is not a valid file.";
	
	list[str] lines = readFileLines(resultsFile);
	list[result] results = [];
	
	// Skip the first lines as it contains the headers.
	for(line <- tail(lines)) 
	{
		parts = split("\t", line);
		
		results += <
			parts[0], // str organisation
			parts[1], // str name
			parts[2], // str revision,
			toInt(parts[3]), // int dependencies, 
			toInt(parts[4]), // int all_classFileCount,
			toInt(parts[5]), // int all_classCount,
			toInt(parts[6]), // int all_interfaceCount,							// Looks like concat of all_publicInterfaceCount and all_packageVisibleInterfaceCount instead of sum.
			toInt(parts[7]), // int all_publicClassCount,
			toInt(parts[8]), // int all_packageVisibleClassCount,
			toInt(parts[9]), // int all_publicInterfaceCount,
			toInt(parts[10]), // int all_packageVisibleInterfaceCount,
			toInt(parts[11]), // int project_classFileCount, 
			toInt(parts[12]), // int project_classCount,
			toInt(parts[13]), // int project_interfaceCount,					// Looks like concat of project_publicInterfaceCount and project_packageVisibleInterfaceCount instead of sum.
			toInt(parts[14]), // int project_publicClassCount,
			toInt(parts[15]), // int project_packageVisibleClassCount,
			toInt(parts[16]), // int project_publicInterfaceCount,
			toInt(parts[17]), // int project_packageVisibleInterfaceCount,
			toInt(parts[18]), // int libraries_classFileCount,
			toInt(parts[19]), // int libraries_classCount,
			toInt(parts[20]), // int libraries_interfaceCount,
			toInt(parts[21]), // int libraries_publicClassCount,
			toInt(parts[22]), // int libraries_packageVisibleClassCount,
			toInt(parts[23]), // int libraries_publicInterfaceCount,
			toInt(parts[24]), // int libraries_packageVisibleInterfaceCount,
			toInt(parts[25]), // int all_methodCount,
			toInt(parts[26]), // int all_publicMethods,
			toInt(parts[27]), // int all_protectedMethods,
			toInt(parts[28]), // int all_packagePrivateMethods,
			toInt(parts[29]), // int all_privateMethods,
			toInt(parts[30]), // int project_methodCount,
			toInt(parts[31]), // int project_publicMethods,
			toInt(parts[32]), // int project_protectedMethods,
			toInt(parts[33]), // int project_packagePrivateMethods,
			toInt(parts[34]), // int project_privateMethods,
			toInt(parts[35]), // int libraries_methodCount,
			toInt(parts[36]), // int libraries_publicMethods,
			toInt(parts[37]), // int libraries_protectedMethods,
			toInt(parts[38]), // int libraries_packagePrivateMethods,
			toInt(parts[39]), // int libraries_privateMethods,
			toInt(parts[40]), // int old_entryPoints,
			toInt(parts[41]), // int old_callEdgesCount,
			toReal(parts[42]),	// num old_EntryPointCalculationTime,
			toReal(parts[43]),	// num old_callGraphBuildTime,
			parts[44],			// str old_Memory,
			toInt(parts[45]),	// int opa_entryPoints,
			toInt(parts[46]),	// int opa_callEdgesCount,
			toInt(parts[47]),	// int opa_callBySignatureEdgesCount,
			toReal(parts[48]),	// num opa_EntryPointCalculationTime,
			toReal(parts[49]),	// num opa_callGraphBuildTime,
			parts[50],			// str opa_Memory,
			toInt(parts[51]),	// int cpa_entryPoints,
			toInt(parts[52]),	// int cpa_callEdgesCount,
			toInt(parts[53]),	// int cpa_callBySignatureEdgesCount,
			toReal(parts[54]),	// num cpa_EntryPointCalculationTime,
			toReal(parts[55]),	// num cpa_callGraphBuildTime,
			parts[56]			// str cpa_Memory
			>;
	}
	return results;
}
