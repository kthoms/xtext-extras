/*******************************************************************************
 * Copyright (c) 2010 itemis AG (http://www.itemis.eu) and others.
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *******************************************************************************/
package org.eclipse.xtext.xbase.tests.compiler;

import org.eclipse.emf.ecore.EObject;
import org.eclipse.xtext.xbase.compiler.IAppendable;
import org.eclipse.xtext.xbase.compiler.XbaseCompiler;
import org.eclipse.xtext.xbase.tests.AbstractXbaseTestCase;

/**
 * @author Sven Efftinge - Initial contribution and API
 */
public class CompilerTest extends AbstractXbaseTestCase {
	
	public void testSimple() throws Exception {
		assertCompilesTo("\njava.lang.Integer _var = \"foo\".length();\n" + 
				"return _var;", "'foo'.length");
	}
	
	public void testBlock() throws Exception {
		assertCompilesTo(
				"\njava.lang.Integer _var = null;\n" +
				"{\n" +
				"  final java.util.ArrayList<java.lang.String> _this = new java.util.ArrayList<java.lang.String>();\n" +
				"  java.lang.Integer _var_1 = _this.size();\n" + 
				"  _var = (_var_1);\n" +
				"}\n" +
				"return _var;"
				, "{ val this = new java.util.ArrayList<String>(); size;}");
	}
	
	public void testIf() throws Exception {
		assertCompilesTo(
				"\njava.lang.Integer _var = null;\n" +
				"if (true) {\n" +
				"  _var = new Integer(42);\n" +
				"} else {\n" +
				"  _var = new Integer(21);\n}\n" +
				"return _var;"
				, "if (true) 42 else 21");
	}

	public void testForEach() throws Exception {
		assertCompilesTo(
				"\nfor (java.lang.String s : new java.util.ArrayList<java.lang.String>()) {\n" +
				"  s.length();\n" +
				"}\n" +
				"return null;"
				, "for (String s : new java.util.ArrayList<String>()) " +
						"s.length");
	}
	
	protected void assertCompilesTo(final String expectedJavaCode, final String xbaseCode) throws Exception {
		EObject model = expression(xbaseCode,true);
		XbaseCompiler compiler = get(XbaseCompiler.class);
		IAppendable appandable = new IAppendable.StringBuilderBasedAppendable();
		compiler.compile(model,appandable);
		assertEquals(expectedJavaCode,appandable.toString());
	}
}