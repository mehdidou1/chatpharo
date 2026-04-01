Class {
	#name : 'ChatPharoThinkingPresenterTest',
	#superclass : 'TestCase',
	#instVars : [
		'presenter'
	],
	#category : 'AI-ChatPharo-Tests-Thinking',
	#package : 'AI-ChatPharo-Tests',
	#tag : 'Thinking'
}

{ #category : 'running' }
ChatPharoThinkingPresenterTest >> setUp [

	super setUp.
	presenter := ChatPharoThinkingPresenter new
]

{ #category : 'running' }
ChatPharoThinkingPresenterTest >> tearDown [

	presenter ifNotNil: [ presenter stopAnimation ].
	presenter := nil.
	super tearDown
]

{ #category : 'running' }
ChatPharoThinkingPresenterTest >> testAddExecutedToolIgnoresNil [

	presenter addExecutedTool: nil.
	self assert: (presenter instVarNamed: #executedTools) isEmpty
]

{ #category : 'running' }
ChatPharoThinkingPresenterTest >> testAddExecutedToolTracksToolName [

	presenter addExecutedTool: 'search_code'.
	self assert: (presenter instVarNamed: #executedTools) size equals: 1.
	self assert: (presenter instVarNamed: #executedTools) first equals: 'search_code'
]

{ #category : 'running' }
ChatPharoThinkingPresenterTest >> testClearExecutedToolsRemovesAll [

	presenter addExecutedTool: 'search_code'.
	presenter addExecutedTool: 'run_snippet'.
	presenter clearExecutedTools.
	self assert: (presenter instVarNamed: #executedTools) isEmpty
]

{ #category : 'running' }
ChatPharoThinkingPresenterTest >> testFormattedElapsedThinkingTime [

	presenter instVarNamed: #thinkingElapsedSeconds put: 125.

	self
		assert: presenter formattedElapsedThinkingTime
		equals: '2 min 5 sec (125s total)'
]

{ #category : 'running' }
ChatPharoThinkingPresenterTest >> testPhaseFinishedUpdatesStatusWithElapsedTime [
| buttonLabel |
	presenter
		instVarNamed: #thinkingStartedAt
		put: DateAndTime now - (Duration seconds: 65).

	presenter phase: #finished.
	buttonLabel := (presenter instVarNamed: #thinkingButton) label.
self assert: (buttonLabel includesSubstring: 'Done').
	self assert: (buttonLabel includesSubstring: '65s')
]

{ #category : 'running' }
ChatPharoThinkingPresenterTest >> testStartAnimationClearsExecutedTools [

	presenter addExecutedTool: 'search_code'.
	presenter startAnimation.
	self assert: (presenter instVarNamed: #executedTools) isEmpty
]

{ #category : 'running' }
ChatPharoThinkingPresenterTest >> testStartAnimationResetsAndStartsTiming [

	presenter instVarNamed: #thinkingElapsedSeconds put: 42.
	presenter startAnimation.

	self assert: (presenter instVarNamed: #thinkingStartedAt) isNotNil.
	self assert: (presenter instVarNamed: #thinkingElapsedSeconds) equals: 0
]
