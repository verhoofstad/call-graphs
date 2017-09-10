module \test::rta::RtaCase

import Prelude;
import lang::java::m3::Core;
import lang::java::m3::AST;
import lang::java::jdt::m3::Core;
import lang::java::m3::TypeHierarchy;

import analysis::m3::Core;

anno rel[loc declaration, loc annotation] M3@annotations;

public M3 rtaModel = m3(|project://rtaCase|)[
	@annotations = {
		<|java+method:///Apple/edible()|,|java+interface:///java/lang/Override|>,
    	<|java+method:///Fruit/edible()|,|java+interface:///java/lang/Override|>
    }];



//rtaModel@annotations;

