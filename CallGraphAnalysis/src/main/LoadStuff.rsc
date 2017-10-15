module LoadStuff

import Prelude;
import lang::java::m3::Core;
import lang::java::m3::AST;
import lang::java::m3::TypeHierarchy;
import lang::java::jdt::m3::Core;
import analysis::graphs::Graph;

import main::Util;
import main::M3Extensions;
import main::rta::Sets;
import main::rta::ClassHierarchyGraph;
import main::rta::OverrideFrontier;
import main::rta::ProgramVirtualCallGraph;
import main::rta::RapidTypeAnalysis;
import main::rta::ResolveCalls;

import main::rta::Util;

M3 m3RtaCase = createM3FromEclipseProject(|project://RtaCase|);
M3 m3RtaCase2 = createM3FromEclipseProject(|project://RtaCase2|);
M3 m3TestCases = createM3FromEclipseProject(|project://TestCases|);
  
M3 model1 = createM3FromDirectory(|file:///C:/Users/Erik/OneDrive/Mijn%20documenten/ThesisWS/TestCases/src|);