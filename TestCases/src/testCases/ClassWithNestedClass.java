package testCases;

public class ClassWithNestedClass {
	
	
	public void callingNestedMethod() {
	
		NestedClass obj1 = new NestedClass();
		obj1.nestedMethod();
	}
	
	
	public class NestedClass
	{
		
		
		public void nestedMethod() { }
	}

}
