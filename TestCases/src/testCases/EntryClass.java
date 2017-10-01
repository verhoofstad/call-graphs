package testCases;

import nested.*;

public class EntryClass
{
	public static void main(String[] args) 
	{
		A testF = new F();
		A testB = new B();
		
		
		testB.m();
		
		testF.p();
		testF.m();
		
		OuterClass testA = new OuterClass();
		
		OuterClass.NestedPublicClass testO = testA.new NestedPublicClass();
	}
}