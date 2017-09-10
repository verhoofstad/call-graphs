package m3Extensions;

public class SomeClass  {

	public void SomeMethod() {
	
		SomeClass anonymousClass = new SomeClass() { };
	
		WithParameterizedConstructor anonymous2 = new WithParameterizedConstructor() { };

		WithParameterizedConstructor anonymous3 = new WithParameterizedConstructor("name") { };
		
		SomeInterface anonymous4 = new SomeInterface() { };
	}
	
	
	private class PrivateClass
	{
		
	}
	
}
