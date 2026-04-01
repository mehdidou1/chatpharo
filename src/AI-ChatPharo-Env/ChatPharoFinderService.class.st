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

{ #category : 'initialization' }
ChatPharoFinderService >> initialize [

    super initialize.
    model := StFinderModel new.
]

{ #category : 'initialization' }
ChatPharoFinderService >> searchWith: searchClass
        query: queryString
        packages: packageNames
        caseSensitive: caseSensitive
        exact: exact
        regex: regex [

    | results |
    model currentSearch: (searchClass new application: model application; yourself).

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
