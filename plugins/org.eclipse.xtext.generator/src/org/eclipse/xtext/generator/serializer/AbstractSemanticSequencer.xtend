package org.eclipse.xtext.generator.serializer

import org.eclipse.xtext.generator.grammarAccess.GrammarAccess
import java.util.List
import org.eclipse.xtext.serializer.impl.GrammarConstraintProvider
import org.eclipse.xtext.serializer.IGrammarConstraintProvider$IConstraint
import org.eclipse.xtext.Grammar
import static extension org.eclipse.xtext.generator.GenModelAccess.*
import static extension org.eclipse.xtext.generator.serializer.SemanticSequencerUtil.*
import org.eclipse.emf.ecore.EPackage
import org.eclipse.emf.ecore.EClass
import com.google.common.collect.Lists
import java.util.Map
import org.eclipse.xtext.serializer.IGrammarConstraintProvider

class AbstractSemanticSequencer extends GeneratedJavaClass {
	
	@Inject Grammar
	
	@Inject extension GrammarAccess
	
	override String getQualifiedName() {
		getName("Abstract", "SemanticSequencer");		
	}
	
	foo(Map<String, String> m) { '''�FOR e:m.entrySet��ENDFOR�''' }
	
	Iterable<EPackage> getAccessedPackages() {
		grammar.grammarConstraints.map(e|e.type.EPackage).toSet
	}
	
	Iterable<EClass> getAccessedClasses(EPackage pkg) {
		grammar.grammarConstraints.map(e|e.type).filter(e|e.EPackage == pkg)
	}
	
	Iterable<EClass> getAccessedClasses() {
		grammar.grammarConstraints.map(e|e.type).toSet
	}
	
	getAccessedConstraints(EClass clazz) {
		grammar.getGrammarConstraints(clazz)
	}
	
	getAccessedContexts(EClass clazz) {
		grammar.getGrammarContexts(clazz)
	}
	
	getAccessedContexts() {
		grammar.getGrammarContexts()
	}
	
	getAccessedConstraints() {
		grammar.getGrammarConstraints()
	}
	
	
	override String getFileContents() {	'''
		package �packageName�;
		
		import java.util.Collections;
		import static java.util.Collections.singleton;
		
		import org.eclipse.emf.ecore.EObject;
		import org.eclipse.xtext.nodemodel.ICompositeNode;
		import org.eclipse.xtext.nodemodel.ILeafNode;
		import org.eclipse.xtext.serializer.GenericSequencer;
		import org.eclipse.xtext.serializer.ISemanticNodeProvider;
		import org.eclipse.xtext.serializer.ISemanticNodeProvider.INodesForEObjectProvider;
		import org.eclipse.xtext.serializer.ISemanticSequencer;
		import org.eclipse.xtext.serializer.ITransientValueService;
		import org.eclipse.xtext.serializer.ITransientValueService.ValueTransient;
		import org.eclipse.xtext.serializer.acceptor.ISemanticSequenceAcceptor;
		import org.eclipse.xtext.serializer.diagnostic.ISemanticSequencerDiagnosticProvider;
		import org.eclipse.xtext.serializer.diagnostic.ISerializationDiagnostic.Acceptor;
		import org.eclipse.xtext.serializer.impl.AbstractSemanticSequencer;
		import �grammar.gaFQName�;
		�FOR e:accessedPackages�
			import �e.genPackage.qualifiedPackageName�.*;
		�ENDFOR�
		
		import com.google.common.collect.Lists;
		import com.google.inject.Inject;
		
		public class �simpleName� extends AbstractSemanticSequencer {
		
			@Inject
			protected �grammar.gaSimpleName� grammarAccess;
			
			@Inject
			@GenericSequencer
			protected ISemanticSequencer genericSequencer;
			
			@Inject
			protected ISemanticSequencerDiagnosticProvider diagnosticProvider;
			
			@Inject
			protected ITransientValueService transientValues;
			
			@Inject
			protected ISemanticNodeProvider nodeProvider;
			
			�genMethodFindContext�	
			
			�accessedClasses.filter(e|e.accessedContexts.size > 1).elementsToString("\n\n", [e|e.genMethodFindContextType()])�
			
			�genMethodCreateSequence�
			
			�accessedConstraints.elementsToString("\n\n",[e|e.genMethodSequence])�
		}
		'''.toString
	}
	
	String genMethodFindContext() { '''
		public Iterable<EObject> findContexts(EObject obj, Iterable<EObject> contextCandidates) {
			�var pkgi = 0�
			�FOR pkg:accessedPackages  /* ITERATOR i */�
				�IF (pkgi = pkgi + 1) > 1 /* !i.firstIteration */�else �ENDIF�if(obj.eClass().getEPackage() == �pkg.genPackage.packageInterfaceName�.eINSTANCE) switch(obj.eClass().getClassifierID()) {
					�val width = pkg.accessedClasses.fold(0, [type, max | Math::max(type.genIntLiteral.length, max)])�
					�FOR type:pkg.accessedClasses�
						case �type.genIntLiteral�:�{type.genIntLiteral.length..width}.fold("",[i,s|s + " "])�return �IF type.accessedContexts.size == 1�singleton((EObject)grammarAccess.�type.accessedContexts.iterator.next.gaAccessor()�)�ELSE�findContexts((�type.getGenClass().interfaceName�)obj)�ENDIF�;
					�ENDFOR�
				}		
			�ENDFOR�	
			return Collections.emptyList();
		}
		
		�FOR type:accessedClasses.filter(e|e.accessedContexts.size > 1)�
		
		�ENDFOR�
		'''.toString
	}
	
	String genMethodFindContextType(EClass type) { '''
		protected Iterable<EObject> findContexts(�type.genClass().interfaceName� obj) {
			return Lists.newArrayList(�FOR ctx:type.accessedContexts SEPARATOR ", "�grammarAccess.�ctx.gaAccessor��ENDFOR�);
		}
		'''.toString
	}
	
	String genMethodCreateSequence() { '''
		public void createSequence(EObject context, EObject semanticObject, ISemanticSequenceAcceptor sequenceAcceptor,	Acceptor errorAcceptor) {
			�var pkgi = 0 �		
			�FOR pkg:accessedPackages /* ITERATOR i */�
			�IF (pkgi = pkgi + 1) > 1 /*!i.firstIteration */�else �ENDIF�if(semanticObject.eClass().getEPackage() == �pkg.getGenPackage().packageInterfaceName�.eINSTANCE) switch(semanticObject.eClass().getClassifierID()) {
				�FOR type:pkg.accessedClasses�
				case �type.genIntLiteral�:
					�var ctxi = 0�
					�FOR ctx: type.accessedConstraints.entrySet /* ITERATOR j-  */�
						�IF (ctxi = ctxi + 1) > 1 /*!j.firstIteration  */�else �ENDIF�if(�FOR c:ctx.value SEPARATOR " ||\n   "�context == grammarAccess.�c.gaAccessor��ENDFOR�) {
							sequence_�ctx.key.name�(context, (�type.name�) semanticObject, sequenceAcceptor, errorAcceptor); 
							return; 
						}
					�ENDFOR�
				�ENDFOR�
				}
				if (errorAcceptor != null) errorAcceptor.accept(diagnosticProvider.createInvalidContextOrTypeDiagnostic(semanticObject, context));
			�ENDFOR�
		}'''.toString
	}
	
	String genMethodSequence(IGrammarConstraintProvider$IConstraint c) {'''
		/**
		 * Constraint:
		 *     �c.body�
		 *
		 * Features:
		�FOR f:c.features�
			�" *    "��f.toString().replaceAll("\\n","\n *     ")�
		�ENDFOR�
		 */
		protected void sequence_�c.name�(EObject context, �c.type.getGenClass().interfaceName� semanticObject, ISemanticSequenceAcceptor sequenceAcceptor, Acceptor errorAcceptor) {
			�IF c.canGenerate()�
				if(errorAcceptor != null) {
					�FOR f:c.features�
						if(transientValues.isValueTransient(semanticObject, �f.feature.genTypeLiteral�) == ValueTransient.YES)
							errorAcceptor.accept(diagnosticProvider.createFeatureValueMissing(semanticObject, �f.feature.genTypeLiteral�));
					�ENDFOR�
				}
				INodesForEObjectProvider nodes = nodeProvider.getNodesForSemanticObject(semanticObject, null);
				�FOR f:c.features�
					�val assignment=f.assignments.get(0)�
					�assignment.type.toAcceptMethod()�(sequenceAcceptor, errorAcceptor, semanticObject, grammarAccess.�assignment.grammarElement.gaAccessor()�, semanticObject.get�f.feature.getGenFeature().accessorName�(), -1, (�assignment.type.toNodeType�)nodes.getNodeForSingelValue(�f.feature.genTypeLiteral�, semanticObject.get�f.feature.getGenFeature().accessorName�()));
				�ENDFOR�
			�ELSE�
				genericSequencer.createSequence(context, semanticObject, sequenceAcceptor, errorAcceptor);
			�ENDIF�
		}'''.toString
	}
}

