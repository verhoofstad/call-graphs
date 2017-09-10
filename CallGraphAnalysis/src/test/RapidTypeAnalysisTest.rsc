module \test::RapidTypeAnalysisTest

import main::cha::ClassHierarchyAnalysis;


M3 testCases = createM3FromEclipseProject(|project://TestCases|);


test bool callGraphOk() 
{
	cha = runChaAnalysis(testCases);
	
	rta = runRtaAnalysis(testCases, cha);
	
	assert !isEmpty(rta) : "Call graph should not be empty.";
	
	
	assert <|java+method:///testCases/EntryClass/main(java.lang.String%5B%5D)|,|java+constructor:///testCases/F/F()|> in rta;
	
  	assert <|java+method:///testCases/EntryClass/main(java.lang.String%5B%5D)|,|java+method:///testCases/A/p()|> in rta;
  	assert <|java+method:///testCases/EntryClass/main(java.lang.String%5B%5D)|,|java+method:///testCases/F/p()|> in rta;

  	assert <|java+method:///testCases/EntryClass/main(java.lang.String%5B%5D)|,|java+method:///testCases/SomeClass/DoItStaticly()|> in rta;
	assert <|java+method:///testCases/EntryClass/main(java.lang.String%5B%5D)|,|java+constructor:///testCases/Serial/Serial()|> in rta;
  	assert <|java+method:///testCases/EntryClass/main(java.lang.String%5B%5D)|,|java+method:///testCases/Serial/AnoniemeKlass()|> in rta;

	/*
  <|java+method:///testCases/F/p()|,|java+method:///testCases/C/m()|>,
  <|java+method:///testCases/Serial/AnoniemeKlass()|,|java+constructor:///testCases/Serial/AnoniemeKlass()/$anonymous1/()|>,
  <|java+method:///testCases/Serial/AnoniemeKlass()|,|java+method:///testCases/HelloWorld/greetSomeone(java.lang.String)|>,
  <|java+method:///testCases/Serial/AnoniemeKlass()|,|java+method:///testCases/Serial/AnoniemeKlass()/$anonymous1/greetSomeone(java.lang.String)|>,
  <|java+method:///testCases/SomeClass/DoItStaticly()|,|java+constructor:///testCases/A/A()|>,
  <|java+method:///testCases/SomeClass/DoItStaticly()|,|java+constructor:///testCases/B/B()|>,
  <|java+method:///testCases/SomeClass/DoItStaticly()|,|java+method:///testCases/A/m()|>,
  <|java+method:///testCases/SomeClass/DoItStaticly()|,|java+method:///testCases/B/m()|>,
  <|java+method:///testCases/SomeClass/DoItStaticly()|,|java+method:///testCases/C/m()|>
	*/
}

/*
	public static void main(String[] args) 
	{
		A test = new F();
		test.p();
		
		SomeClass.DoItStaticly();
		
		Serial ser = new Serial();
		
		ser.AnoniemeKlass();
	}
	*/