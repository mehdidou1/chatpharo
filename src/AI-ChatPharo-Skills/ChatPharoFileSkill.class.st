"
A skill whose content is loaded from an external file on disk.
File format: an optional header block of ``key: value`` lines terminated by a
line containing only ``---``, followed by the skill body. Recognised headers:
- ``name`` - unique skill identifier (defaults to the file base name)
- ``description`` - short description shown in the settings UI
- ``keywords`` - comma-separated list used for automatic activation
If no header is present the whole file is treated as the context body.
Users add file skills via Settings > Skills. Paths are persisted in
``ChatPharoSettings>>skillFilePaths`` and loaded into the registry on refresh.
"
Class {
	#name : 'ChatPharoFileSkill',
	#superclass : 'ChatPharoSkill',
	#instVars : [
		'filePath',
		'name',
		'description',
		'keywords',
		'contextString'
	],
	#category : 'AI-ChatPharo-Skills',
	#package : 'AI-ChatPharo-Skills'
}

{ #category : 'instance creation' }
ChatPharoFileSkill class >> fromFile: aPathString [

	^ self new loadFromFile: aPathString
]

{ #category : 'instance creation' }
ChatPharoFileSkill class >> isAbstract [

	^ true
]

{ #category : 'accessing' }
ChatPharoFileSkill >> contextString [

	^ contextString ifNil: [ '' ]
]

{ #category : 'accessing' }
ChatPharoFileSkill >> description [

	^ description ifNil: [ 'Skill loaded from file: ' , self filePath asString ]
]

{ #category : 'accessing' }
ChatPharoFileSkill >> filePath [

	^ filePath
]

{ #category : 'accessing' }
ChatPharoFileSkill >> keywords [

	^ keywords ifNil: [ #() ]
]

{ #category : 'accessing' }
ChatPharoFileSkill >> loadFromFile: aPathString [

	| ref contents |
	filePath := aPathString.
	ref := aPathString asFileReference.
	ref exists ifFalse: [
		name := ref basenameWithoutExtension.
		description := 'Missing skill file: ' , aPathString asString.
		keywords := #().
		contextString := ''.
		^ self ].
	contents := ref readStreamDo: [ :s | s upToEnd ].
	self parseContents: contents defaultName: ref basenameWithoutExtension.
	cachedNormalizedKeywords := nil
]

{ #category : 'accessing' }
ChatPharoFileSkill >> name [

	^ name ifNil: [ 'FileSkill' ]
]

{ #category : 'accessing' }
ChatPharoFileSkill >> parseContents: aString defaultName: aDefaultName [

	| lines index inHeader headerDone bodyLines |
	name := aDefaultName.
	description := nil.
	keywords := #().
	lines := aString lines.
	headerDone := false.
	inHeader := true.
	bodyLines := OrderedCollection new.
	index := 1.
	[ inHeader and: [ index <= lines size ] ] whileTrue: [
		| line trimmed |
		line := lines at: index.
		trimmed := line trimBoth.
		trimmed = '---'
			ifTrue: [
				inHeader := false.
				headerDone := true.
				index := index + 1 ]
			ifFalse: [
				(trimmed includesSubstring: ':')
					ifTrue: [
						| colon key value |
						colon := trimmed indexOf: $:.
						key := (trimmed copyFrom: 1 to: colon - 1) trimBoth asLowercase.
						value := (trimmed copyFrom: colon + 1 to: trimmed size) trimBoth.
						key = 'name' ifTrue: [ name := value ].
						key = 'description' ifTrue: [ description := value ].
						key = 'keywords' ifTrue: [
							keywords := (value substrings: ',')
								collect: [ :k | k trimBoth ] ].
						index := index + 1 ]
					ifFalse: [ inHeader := false ] ] ].
	headerDone
		ifTrue: [ bodyLines addAll: (lines copyFrom: index to: lines size) ]
		ifFalse: [ bodyLines addAll: lines ].
	contextString := (String lf join: bodyLines)
]
