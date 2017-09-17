module main::results::ResultSet

alias result = tuple[
	str organisation,
	str name,
	str revision,
	int dependencies, 
	int all_classFileCount,
	int all_classCount,
	int all_interfaceCount,
	int all_publicClassCount,
	int all_packageVisibleClassCount,
	int all_publicInterfaceCount,
	int all_packageVisibleInterfaceCount,
	int project_classFileCount, 
	int project_classCount,
	int project_interfaceCount,
	int project_publicClassCount,
	int project_packageVisibleClassCount,
	int project_publicInterfaceCount,
	int project_packageVisibleInterfaceCount,
	int libraries_classFileCount,
	int libraries_classCount,
	int libraries_interfaceCount,
	int libraries_publicClassCount,
	int libraries_packageVisibleClassCount,
	int libraries_publicInterfaceCount,
	int libraries_packageVisibleInterfaceCount,
	int all_methodCount,
	int all_publicMethods,
	int all_protectedMethods,
	int all_packagePrivateMethods,
	int all_privateMethods,
	int project_methodCount,
	int project_publicMethods,
	int project_protectedMethods,
	int project_packagePrivateMethods,
	int project_privateMethods,
	int libraries_methodCount,
	int libraries_publicMethods,
	int libraries_protectedMethods,
	int libraries_packagePrivateMethods,
	int libraries_privateMethods,
	int old_entryPoints,
	int old_callEdgesCount,
	num old_EntryPointCalculationTime,
	num old_callGraphBuildTime,
	str old_Memory,
	int opa_entryPoints,
	int opa_callEdgesCount,
	int opa_callBySignatureEdgesCount,
	num opa_EntryPointCalculationTime,
	num opa_callGraphBuildTime,
	str opa_Memory,
	int cpa_entryPoints,
	int cpa_callEdgesCount,
	int cpa_callBySignatureEdgesCount,
	num cpa_EntryPointCalculationTime,
	num cpa_callGraphBuildTime,
	str cpa_Memory
];