package testCases;

public class A
	implements IntA
{
	public void m() {}
	
	public void p() {}
	
	static {
		
		B obj = new B();
		
		obj.p();
		
	}
}