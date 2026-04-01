Class {
	#name : 'ChatPharoDebuggerContextTest',
	#superclass : 'TestCase',
	#category : 'AI-ChatPharo-Tests-Debugger',
	#package : 'AI-ChatPharo-Tests',
	#tag : 'Debugger'
}

{ #category : 'tests' }
ChatPharoDebuggerContextTest >> testBasicCreation [

	| ctx |
	ctx := ChatPharoDebuggerContext new.
	self assert: ctx errorClassName isNil.
	self assert: ctx errorMessage isNil.
	self assert: ctx stackTrace isNil.
	self assert: ctx failingMethodSource isNil.
	self assert: ctx localVariables isNil.
	self assert: ctx receiverState isNil
]

{ #category : 'tests' }
ChatPharoDebuggerContextTest >> testCaptureMethodInfo [

	| ctx method |
	method := OrderedCollection >> #add:.
	ctx := ChatPharoDebuggerContext new.
	ctx captureMethodInfo: method.
	self assert: ctx failingClassName equals: 'OrderedCollection'.
	self assert: ctx failingSelector equals: 'add:'.
	self assert: ctx failingMethodSource notNil.
	self deny: ctx failingMethodSource isEmpty
]

{ #category : 'tests' }
ChatPharoDebuggerContextTest >> testCaptureStackFromContext [

	| ctx |
	"Trigger an error and capture context from the handler"
	[ 1 / 0 ]
		on: ZeroDivide
		do: [ :ex |
			ctx := ChatPharoDebuggerContext new.
			ctx captureStackFrom: thisContext.
			self assert: ctx stackTrace notNil.
			self assert: ctx stackTrace notEmpty.
			self assert: (ctx stackTrace first includesSubstring: 'ChatPharoDebuggerContextTest') ]
]

{ #category : 'tests' }
ChatPharoDebuggerContextTest >> testDiagnosticPromptContainsErrorInfo [

	| ctx prompt |
	ctx := ChatPharoDebuggerContext new.
	ctx errorClassName: 'MessageNotUnderstood'.
	ctx errorMessage: 'UndefinedObject>>foo'.
	ctx failingClassName: 'MyClass'.
	ctx failingSelector: 'doSomething'.
	ctx failingMethodSource: 'doSomething
	^ self foo'.
	ctx stackTrace: #( 'MyClass>>doSomething' 'UndefinedObject(Object)>>doesNotUnderstand:' ).
	ctx localVariables: (Dictionary with: 'temp' -> '42').
	ctx receiverClassName: 'MyClass'.
	ctx receiverState: (Dictionary with: 'name' -> '''hello''').

	prompt := ctx diagnosticPrompt.

	self assert: (prompt includesSubstring: 'MessageNotUnderstood').
	self assert: (prompt includesSubstring: 'UndefinedObject>>foo').
	self assert: (prompt includesSubstring: 'MyClass').
	self assert: (prompt includesSubstring: 'doSomething').
	self assert: (prompt includesSubstring: 'self foo').
	self assert: (prompt includesSubstring: 'MyClass>>doSomething').
	self assert: (prompt includesSubstring: 'temp').
	self assert: (prompt includesSubstring: '42').
	self assert: (prompt includesSubstring: 'hello')
]

{ #category : 'tests' }
ChatPharoDebuggerContextTest >> testDiagnosticPromptWithMinimalInfo [

	| ctx prompt |
	ctx := ChatPharoDebuggerContext new.
	prompt := ctx diagnosticPrompt.
	self assert: (prompt includesSubstring: 'debugging an error').
	self assert: (prompt includesSubstring: 'Unknown')
]

{ #category : 'tests' }
ChatPharoDebuggerContextTest >> testForErrorMethod [

	| ctx method |
	method := Object >> #yourself.
	ctx := ChatPharoDebuggerContext forError: 'Something went wrong' method: method.
	self assert: ctx errorClassName equals: 'Error'.
	self assert: ctx errorMessage equals: 'Something went wrong'.
	self assert: ctx failingClassName equals: 'Object'.
	self assert: ctx failingSelector equals: 'yourself'
]

{ #category : 'tests' }
ChatPharoDebuggerContextTest >> testSystemPromptForDebugging [

	| ctx prompt |
	ctx := ChatPharoDebuggerContext new.
	prompt := ctx systemPromptForDebugging.
	self assert: (prompt includesSubstring: 'expert').
	self assert: (prompt includesSubstring: 'Pharo').
	self assert: (prompt includesSubstring: 'debugger')
]
