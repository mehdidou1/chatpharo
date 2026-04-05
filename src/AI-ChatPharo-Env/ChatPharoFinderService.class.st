"
Adapter around Pharo's Spec2 `StFinderModel`, exposing it as a plain
Smalltalk service the LLM tool-layer can drive.
Accepts a high-level search type (`class_name`, `selector`, `source`,
`pragma`) together with an optional package scope and search flags
(case sensitive / exact / regex), runs the search, and serialises the
raw finder result into a JSON-friendly structure suitable for being
returned from a `ChatPharoClient` tool block.
"
Class {
	#name : 'ChatPharoFinderService',
	#superclass : 'Object',
	#instVars : [
		'model'
	],
	#category : 'AI-ChatPharo-Env-Finder',
	#package : 'AI-ChatPharo-Env',
	#tag : 'Finder'
}

{ #category : 'as yet unclassified' }
ChatPharoFinderService class >> availableSearchTypes [
	"The set of search types that can be passed to
	 #searchType:query:packages:caseSensitive:exact:regex:."

	^ #( 'class_name' 'selector' 'source' 'pragma' )
]

{ #category : 'as yet unclassified' }
ChatPharoFinderService class >> searchClassNamed: aString [

	| globalName |
	globalName := Dictionary new
		at: 'class_name' put: #StFinderClassSearch;
		at: 'selector'   put: #StFinderSelectorSearch;
		at: 'source'     put: #StFinderSourceSearch;
		at: 'pragma'     put: #StFinderPragmaSearch;
		yourself.
	^ Smalltalk
		at: (globalName at: aString ifAbsent: [ ^ nil ])
		ifAbsent: [ nil ]
]

{ #category : 'serializing' }
ChatPharoFinderService >> finderItemAsDictionary: item [
	"Render a single finder result entry as a plain Dictionary."

	item isBehavior ifTrue: [
		^ Dictionary new
			at: 'kind' put: 'class';
			at: 'name' put: item name asString;
			at: 'package' put: ([ item package name asString ]
				on: Error do: [ :e | nil ]);
			yourself ].
	(item isKindOf: CompiledMethod) ifTrue: [
		^ Dictionary new
			at: 'kind' put: 'method';
			at: 'class' put: item methodClass name asString;
			at: 'selector' put: item selector asString;
			at: 'package' put: ([ item package name asString ]
				on: Error do: [ :e | nil ]);
			yourself ].
	item isSymbol ifTrue: [
		^ Dictionary new
			at: 'kind' put: 'selector';
			at: 'name' put: item asString;
			yourself ].
	item isString ifTrue: [
		^ Dictionary new
			at: 'kind' put: 'string';
			at: 'value' put: item;
			yourself ].
	^ Dictionary new
		at: 'kind' put: 'other';
		at: 'value' put: item printString;
		yourself
]

{ #category : 'serializing' }
ChatPharoFinderService >> finderItemAsString: item [
	"Best-effort short string rendering of a finder key/value."

	item isBehavior ifTrue: [ ^ item name asString ].
	item isString ifTrue: [ ^ item ].
	item isSymbol ifTrue: [ ^ item asString ].
	^ item printString
]

{ #category : 'serializing' }
ChatPharoFinderService >> finderValueAsList: value [

	(value isCollection and: [ value isString not ])
		ifTrue: [ ^ (value collect: [ :each | self finderItemAsString: each ])
					asArray ].
	^ Array with: (self finderItemAsString: value)
]

{ #category : 'initialization' }
ChatPharoFinderService >> initialize [

    super initialize.
    model := StFinderModel new
]

{ #category : 'initialization' }
ChatPharoFinderService >> model [

	^ model
]

{ #category : 'searching' }
ChatPharoFinderService >> searchType: typeString query: queryString packages: packageNames caseSensitive: caseSensitive exact: exact regex: regex [ 
	| searchClass |
	searchClass := self class searchClassNamed: typeString.
	searchClass ifNil: [
		^ Dictionary new
			at: 'error' put: 'Unknown or unavailable finder search type: ' , typeString printString;
			at: 'available_types' put: self class availableSearchTypes;
			yourself ].
	^ [
		self
			searchWith: searchClass
			query: queryString
			packages: packageNames
			caseSensitive: caseSensitive
			exact: exact
			regex: regex ]
		on: Error
		do: [ :e |
			Dictionary new
				at: 'error' put: 'Finder search failed: ' , e messageText;
				at: 'search_type' put: typeString;
				at: 'query' put: queryString;
				yourself ]
]

{ #category : 'searching' }
ChatPharoFinderService >> searchWith: searchClass query: queryString packages: packageNames caseSensitive: caseSensitive exact: exact regex: regex [

	| results |
	model currentSearch: (searchClass new
		application: model application;
		yourself).

	packageNames
		ifNil: [ model selectAllPackages ]
		ifNotNil: [ model selectedPackagesByName: packageNames ].

	model useCase: caseSensitive.
	model useExact: exact.
	model useRegex: regex.
	model useSubstring: (exact not and: [ regex not ]).

	results := model search: queryString.
	^ self serializeFinderResults: results
]

{ #category : 'serializing' }
ChatPharoFinderService >> serializeFinderResults: results [

	| entries |
	results ifNil: [
		^ Dictionary new
			at: 'results' put: #();
			at: 'count' put: 0;
			yourself ].
	entries := OrderedCollection new.
	results isDictionary
		ifTrue: [
			results keysAndValuesDo: [ :key :value |
				entries add: (Dictionary new
					at: 'class' put: (self finderItemAsString: key);
					at: 'matches' put: (self finderValueAsList: value);
					yourself) ] ]
		ifFalse: [
			(results isCollection and: [ results isString not ])
				ifTrue: [ results do: [ :each |
					entries add: (self finderItemAsDictionary: each) ] ]
				ifFalse: [
					entries add: (self finderItemAsDictionary: results) ] ].
	^ Dictionary new
		at: 'results' put: entries asArray;
		at: 'count' put: entries size;
		yourself
]
