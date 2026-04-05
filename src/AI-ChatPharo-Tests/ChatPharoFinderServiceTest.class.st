Class {
	#name : 'ChatPharoFinderServiceTest',
	#superclass : 'TestCase',
	#instVars : [
		'service'
	],
	#category : 'AI-ChatPharo-Tests-Director',
	#package : 'AI-ChatPharo-Tests',
	#tag : 'Director'
}

{ #category : 'running' }
ChatPharoFinderServiceTest >> setUp [

	super setUp.
	service := ChatPharoFinderService basicNew
]

{ #category : 'running' }
ChatPharoFinderServiceTest >> testAvailableSearchTypesContainsCoreTypes [

	| types |
	types := ChatPharoFinderService availableSearchTypes.
	self assert: (types includes: 'class_name').
	self assert: (types includes: 'selector').
	self assert: (types includes: 'source').
	self assert: (types includes: 'pragma')
]

{ #category : 'running' }
ChatPharoFinderServiceTest >> testFinderEnvironmentExposesFinderSearchTool [

	| env tool |
	env := ChatPharoFinderEnvironment new.
	self assert: env tools size equals: 1.
	tool := env tools first.
	self assert: tool name equals: 'finder_search'.
	self assert: ((tool parameters at: 'required') includes: 'query')
]

{ #category : 'running' }
ChatPharoFinderServiceTest >> testFinderSearchToolEnumMatchesAvailableTypes [

	| tool props searchTypeProp |
	tool := ChatPharoFinderEnvironment new tools first.
	props := tool parameters at: 'properties'.
	searchTypeProp := props at: 'search_type'.
	self
		assert: (searchTypeProp at: 'enum') asArray
		equals: ChatPharoFinderService availableSearchTypes asArray
]

{ #category : 'running' }
ChatPharoFinderServiceTest >> testFinderSearchToolRejectsMissingQuery [

	| env reply |
	env := ChatPharoFinderEnvironment new.
	reply := env applyFunctionFinderSearch: Dictionary new.
	self assert: (reply includesKey: 'error').
	self assert: ((reply at: 'error') includesSubstring: 'query')
]

{ #category : 'running' }
ChatPharoFinderServiceTest >> testSearchClassNamedReturnsNilForUnknownType [

	self assert: (ChatPharoFinderService searchClassNamed: 'nope') isNil
]

{ #category : 'running' }
ChatPharoFinderServiceTest >> testSearchTypeWithUnknownTypeReturnsErrorDictionary [

	| reply |
	reply := service
		searchType: 'not_a_real_type'
		query: 'foo'
		packages: nil
		caseSensitive: false
		exact: false
		regex: false.
	self assert: (reply includesKey: 'error').
	self assert: (reply includesKey: 'available_types')
]

{ #category : 'running' }
ChatPharoFinderServiceTest >> testSerializeClassResult [

	| reply entry results |
	reply := service serializeFinderResults: (Array with: String).
	results := reply at: 'results'.
	self assert: (reply at: 'count') equals: 1.
	entry := results first.
	self assert: (entry at: 'kind') equals: 'class'.
	self assert: (entry at: 'name') equals: 'String'
]

{ #category : 'running' }
ChatPharoFinderServiceTest >> testSerializeDictionaryResult [

	| input reply results entry |
	input := Dictionary new
		at: String put: #( #asUppercase #asLowercase );
		yourself.
	reply := service serializeFinderResults: input.
	results := reply at: 'results'.
	self assert: (reply at: 'count') equals: 1.
	entry := results first.
	self assert: (entry at: 'class') equals: 'String'.
	self assert: ((entry at: 'matches') includes: 'asUppercase').
	self assert: ((entry at: 'matches') includes: 'asLowercase')
]

{ #category : 'running' }
ChatPharoFinderServiceTest >> testSerializeEmptyResult [

	| reply |
	reply := service serializeFinderResults: #().
	self assert: (reply at: 'count') equals: 0.
	self assert: (reply at: 'results') isEmpty
]

{ #category : 'running' }
ChatPharoFinderServiceTest >> testSerializeNilResult [

	| reply |
	reply := service serializeFinderResults: nil.
	self assert: (reply at: 'count') equals: 0.
	self assert: (reply at: 'results') isEmpty
]

{ #category : 'running' }
ChatPharoFinderServiceTest >> testSerializeSelectorResult [

	| reply entry |
	reply := service serializeFinderResults: (Array with: #doSomething).
	entry := (reply at: 'results') first.
	self assert: (entry at: 'kind') equals: 'selector'.
	self assert: (entry at: 'name') equals: 'doSomething'
]
