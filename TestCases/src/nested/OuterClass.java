package nested;

public class OuterClass {
	
	public OuterClass() {
		
		NestedPrivateClass obj1 = new NestedPrivateClass();
		
		obj1.methodInNestedPrivateClass();
		
		
	}
	
	public OuterClass(NestedEnum value) {
		
	}
	
	public static class StaticNestedClass 
	{
		
	}
	
	
	private class NestedPrivateClass
	{
		public void methodInNestedPrivateClass() {
			
		}
	}
	
	public class NestedPublicClass
	{
		public void methodInNestedPublicClass() {
			
		}
	}
	
	public enum NestedEnum
	{
		Value1,
		Value2,
		Value3
	}

}
