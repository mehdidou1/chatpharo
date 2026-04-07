"
System-browser ChatPharo tab specialized for method-level conversations.

It tracks package, class, and selector from the current browser selection and forwards that scope to the agent.
"
Class {
	#name : 'ChatPharoMethodBrowser',
	#superclass : 'ChatPharoPackageBrowser',
	#instVars : [
		'className',
		'methodName'
	],
	#category : 'AI-ChatPharo-Env-System Browser',
	#package : 'AI-ChatPharo-Env',
	#tag : 'System Browser'
}

{ #category : 'testing' }
ChatPharoMethodBrowser class >> shouldBeActivatedInContext: aBrowserContext [

	^ (super shouldBeActivatedInContext: aBrowserContext) and: [ aBrowserContext isMethodSelected ]
]

{ #category : 'accessing' }
ChatPharoMethodBrowser class >> tabOrder [

	^ -12
]

{ #category : 'update' }
ChatPharoMethodBrowser >> chatContextKey [ 

	methodName ifNil: [ ^ super chatContextKey ].
	^ { #method . packageName . className . methodName }
]

{ #category : 'introspection' }
ChatPharoMethodBrowser >> className [

	^ className
]

{ #category : 'introspection' }
ChatPharoMethodBrowser >> className: anObject [

	className := anObject
]

{ #category : 'initialization' }
ChatPharoMethodBrowser >> defaultTitle [

	^ methodName ifNil: [ 'ChatPharo' ]
]

{ #category : 'accessing' }
ChatPharoMethodBrowser >> methodName [

	^ methodName
]

{ #category : 'accessing' }
ChatPharoMethodBrowser >> methodName: anObject [

	methodName := anObject
]

{ #category : 'initialization' }
ChatPharoMethodBrowser >> setUpModelFromContext [

	| methodClass selectedMethod |
	self storeChatForCurrentContext.
	selectedMethod := context lastSelectedMethod.
	selectedMethod ifNil: [ ^ self ].
	methodClass := selectedMethod methodClass.
	className := methodClass ifNotNil: [ :c | c name ].
	packageName := (methodClass notNil and: [ methodClass respondsTo: #package ])
		               ifTrue: [ methodClass package name ]
		               ifFalse: [ nil ].
	methodName := selectedMethod selector.
	self updateAgentPackageName.
	self updateAgentMethodName.
	self updateChatForContext
]

{ #category : 'update' }
ChatPharoMethodBrowser >> updateAgent [ 

super updateAgent.
	self updateAgentMethodName 
]

{ #category : 'update' }
ChatPharoMethodBrowser >> updateAgentMethodName [

	(chat notNil and: [ chat agent respondsTo: #methodName: ]) ifTrue: [
		chat agent methodName: methodName ].
]
