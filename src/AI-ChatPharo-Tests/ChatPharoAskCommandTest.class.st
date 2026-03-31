Class {
	#name : 'ChatPharoAskCommandTest',
	#superclass : 'TestCase',
	#instVars : [
		'originalAskFeatureEnabled'
	],
	#category : 'AI-ChatPharo-Tests-Env',
	#package : 'AI-ChatPharo-Tests',
	#tag : 'Env'
}

{ #category : 'running' }
ChatPharoAskCommandTest >> setUp [

	super setUp.
	originalAskFeatureEnabled := ChatPharoSettings default askFeatureEnabled
]

{ #category : 'running' }
ChatPharoAskCommandTest >> tearDown [

	ChatPharoSettings default askFeatureEnabled: originalAskFeatureEnabled.
	super tearDown
]

{ #category : 'running' }
ChatPharoAskCommandTest >> testCanBeExecutedInContextFalseWhenDisabled [

	| context |
	ChatPharoSettings default askFeatureEnabled: false.
	context := ChatPharoCommandContextStub withSelectedMethodItems: {
		ChatPharoCommandElementStub withBrowserItem:
			(ChatPharoCommandBrowserItemStub withActualObject: Object new) }.
	self deny: (ChatPharoAskCommand canBeExecutedInContext: context)
]

{ #category : 'running' }
ChatPharoAskCommandTest >> testCanBeExecutedInContextFalseWhenEmptySelection [

	| context |
	ChatPharoSettings default askFeatureEnabled: true.
	context := ChatPharoCommandContextStub withSelectedMethodItems: #().
	self deny: (ChatPharoAskCommand canBeExecutedInContext: context)
]

{ #category : 'running' }
ChatPharoAskCommandTest >> testCanBeExecutedInContextTrueWhenEnabledAndSelected [

	| context |
	ChatPharoSettings default askFeatureEnabled: true.
	context := ChatPharoCommandContextStub withSelectedMethodItems: {
		ChatPharoCommandElementStub withBrowserItem:
			(ChatPharoCommandBrowserItemStub withActualObject: Object new) }.
	self assert: (ChatPharoAskCommand canBeExecutedInContext: context)
]

{ #category : 'running' }
ChatPharoAskCommandTest >> testExecuteReturnsSelfWhenElementIsNil [

	| command |
	command := ChatPharoCodeCommand new.
	self assert: command execute identicalTo: command
]

{ #category : 'running' }
ChatPharoAskCommandTest >> testLabelReturnsExpectedString [

	self assert: ChatPharoAskCommand new label equals: 'Ask ChatPharo'
]

{ #category : 'running' }
ChatPharoAskCommandTest >> testReadParametersFromContextUsesFirstSelectedMethodItem [

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

	command := ChatPharoAskCommand new.
	command readParametersFromContext: context.
	command execute.

	self assert: ChatPharoCommandExecutionStub lastAskedMethod identicalTo: method1 ]
		ensure: [ Smalltalk at: #ChatPharo put: originalChatPharo ]
]
