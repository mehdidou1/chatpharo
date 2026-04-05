"
Exposes the system Finder (via `ChatPharoFinderService`) as a set of
`ChatPharoClient` tools that can be plugged into `ChatPharoBrowserEnvironment`.
Currently publishes a single unified tool, `finder_search`, that lets
the LLM search the live image by class name, selector, source text or
pragma, optionally scoping the search to a list of packages.
**Why** – the rest of the browser environment already lets the LLM
inspect specific classes/packages it already knows about; the Finder
complements that by letting the model *discover* classes and methods
it does not know the name of yet.
"
Class {
	#name : 'ChatPharoFinderEnvironment',
	#superclass : 'Object',
	#instVars : [
		'tools'
	],
	#category : 'AI-ChatPharo-Env-Finder',
	#package : 'AI-ChatPharo-Env',
	#tag : 'Finder'
}

{ #category : 'tools' }
ChatPharoFinderEnvironment >> applyFunctionFinderSearch: arguments [

	| query searchType packages caseSensitive exact regex |
	query := arguments at: 'query' ifAbsent: [ '' ].
	query isEmptyOrNil ifTrue: [
		^ Dictionary new
			at: 'error' put: 'Missing required argument: query';
			yourself ].
	searchType := arguments at: 'search_type' ifAbsent: [ 'selector' ].
	packages := arguments at: 'packages' ifAbsent: [ nil ].
	(packages notNil and: [ packages isEmpty ]) ifTrue: [ packages := nil ].
	caseSensitive := arguments at: 'case_sensitive' ifAbsent: [ false ].
	exact := arguments at: 'exact' ifAbsent: [ false ].
	regex := arguments at: 'regex' ifAbsent: [ false ].
	^ ChatPharoFinderService new
		searchType: searchType
		query: query
		packages: packages
		caseSensitive: caseSensitive
		exact: exact
		regex: regex
]

{ #category : 'tools' }
ChatPharoFinderEnvironment >> functionFinderSearch [

	^ ChatPharoClient
		name: 'finder_search'
		description: 'Searches the live Pharo image through the system Finder. Use this to discover classes, selectors, source fragments or pragmas you do not already know by name. The `search_type` parameter selects what to look for: `class_name` (matches class names), `selector` (matches method selectors), `source` (matches the full method source text), or `pragma` (matches method pragmas). You can optionally restrict the search to a list of package names, and control matching with `case_sensitive`, `exact` and `regex` flags (by default the search is a case-insensitive substring match). Results come back as a list of dictionaries describing each matching class or method.'
		parameters: (Dictionary
			with: 'type' -> 'object'
			with: 'properties' -> (Dictionary
				with: 'query' -> (Dictionary
					with: 'type' -> 'string'
					with: 'description' -> 'The text to search for.')
				with: 'search_type' -> (Dictionary
					with: 'type' -> 'string'
					with: 'enum' -> ChatPharoFinderService availableSearchTypes
					with: 'description' -> 'What to match the query against. One of: class_name, selector, source, pragma. Defaults to selector.')
				with: 'packages' -> (Dictionary
					with: 'type' -> 'array'
					with: 'items' -> (Dictionary with: 'type' -> 'string')
					with: 'description' -> 'Optional list of package names to restrict the search to. If omitted, all packages are searched.')
				with: 'case_sensitive' -> (Dictionary
					with: 'type' -> 'boolean'
					with: 'description' -> 'If true, the query is matched case-sensitively. Defaults to false.')
				with: 'exact' -> (Dictionary
					with: 'type' -> 'boolean'
					with: 'description' -> 'If true, require an exact whole-string match instead of a substring match. Defaults to false.')
				with: 'regex' -> (Dictionary
					with: 'type' -> 'boolean'
					with: 'description' -> 'If true, interpret the query as a regular expression. Mutually exclusive with `exact`. Defaults to false.'))
			with: 'required' -> #( 'query' ))
		block: [ :arguments |
			self applyFunctionFinderSearch: arguments ]
]

{ #category : 'initialization' }
ChatPharoFinderEnvironment >> initialize [

	super initialize.
	tools := {
		self functionFinderSearch
	} asOrderedCollection
]

{ #category : 'tools' }
ChatPharoFinderEnvironment >> tools [

	^ tools
]
