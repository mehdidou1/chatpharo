Class {
	#name : 'ChatPharoCodeCommandTest',
	#superclass : 'TestCase',
	#instVars : [
		'originalCodeFeatureEnabled'
	],
	#category : 'AI-ChatPharo-Tests-Env',
	#package : 'AI-ChatPharo-Tests',
	#tag : 'Env'
}

{ #category : 'running' }
ChatPharoCodeCommandTest >> setUp [

	super setUp.
	originalCodeFeatureEnabled := ChatPharoSettings default codeFeatureEnabled
]

{ #category : 'running' }
ChatPharoCodeCommandTest >> tearDown [

	ChatPharoSettings default codeFeatureEnabled: originalCodeFeatureEnabled.
	super tearDown
]

{ #category : 'running' }
ChatPharoCodeCommandTest >> testCanBeExecutedInContextFalseWhenDisabled [

	| context |
	ChatPharoSettings default codeFeatureEnabled: false.
	context := ChatPharoCommandContextStub withSelectedMethodItems: {
		ChatPharoCommandElementStub withBrowserItem:
			(ChatPharoCommandBrowserItemStub withActualObject: Object new) }.
	self deny: (ChatPharoCodeCommand canBeExecutedInContext: context)
]

{ #category : 'running' }
ChatPharoCodeCommandTest >> testCanBeExecutedInContextFalseWhenEmptySelection [

	| context |
	ChatPharoSettings default codeFeatureEnabled: true.
	context := ChatPharoCommandContextStub withSelectedMethodItems: #().
	self deny: (ChatPharoCodeCommand canBeExecutedInContext: context)
]

{ #category : 'running' }
ChatPharoCodeCommandTest >> testCanBeExecutedInContextTrueWhenEnabledAndSelected [

	| context |
	ChatPharoSettings default codeFeatureEnabled: true.
	context := ChatPharoCommandContextStub withSelectedMethodItems: {
		ChatPharoCommandElementStub withBrowserItem:
			(ChatPharoCommandBrowserItemStub withActualObject: Object new) }.
	self assert: (ChatPharoCodeCommand canBeExecutedInContext: context)
]

{ #category : 'running' }
ChatPharoCodeCommandTest >> testLabelReturnsExpectedString [

	self assert: ChatPharoCodeCommand new label equals: 'Code ChatPharo'
]

{ #category : 'running' }
ChatPharoCodeCommandTest >> testReadParametersFromContextUsesFirstSelectedMethodItem [

	| originalChatPharo method1 method2 context command |
	originalChatPharo := Smalltalk at: #ChatPharo.

	[
	Smalltalk at: #ChatPharo put: ChatPharoCommandExecutionStub.
	ChatPharoCommandExecutionStub reset.

	method1 := Object new.
	method2 := Object new.
	context := ChatPharoCommandContextStub withSelectedMethodItems: {
		ChatPharoCommandElementStub withBrowserItem:
			(ChatPharoCommandBrowserItemStub withActualObject: method1).
		ChatPharoCommandElementStub withBrowserItem:
			(ChatPharoCommandBrowserItemStub withActualObject: method2) }.

	command := ChatPharoCodeCommand new.
	command readParametersFromContext: context.
	command execute.

	self assert: ChatPharoCommandExecutionStub lastCodedMethod identicalTo: method1 ]
		ensure: [ Smalltalk at: #ChatPharo put: originalChatPharo ]
]
