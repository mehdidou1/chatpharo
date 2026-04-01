"
Displays the detailed thinking content from Claude AI.
Shows the complete thought process that occurs during AI responses.
"
Class {
	#name : 'ChatPharoThinkingDetailPresenter',
	#superclass : 'SpPresenter',
	#instVars : [
		'thinkingPresenter',
		'phaseLabel',
		'elapsedLabel',
		'modelLabel',
		'toolsText',
		'thinkingText',
		'ethicsSummaryText',
		'closeButton',
		'notebook'
	],
	#category : 'AI-ChatPharo-Spec-Ethics',
	#package : 'AI-ChatPharo-Spec',
	#tag : 'Ethics'
}

{ #category : 'as yet unclassified' }
ChatPharoThinkingDetailPresenter >> buildEthicsSummary [
	"Build a summary of the Ethics Director settings"

	| settings director |
	settings := ChatPharoSettings default.
	director := settings ethicsDirector.

	^ String streamContents: [ :stream |
		stream
			nextPutAll: 'Ethics Director';
			cr;
			nextPutAll: String new , '======================';
			cr; cr.

		stream
			nextPutAll: 'Enabled: ';
			nextPutAll: director enabled asString;
			cr; cr.

		stream
			nextPutAll: 'Mandate:';
			cr;
			nextPutAll: (director mandate ifEmpty: [ '(none)' ]);
			cr; cr.

		stream
			nextPutAll: 'Resource Budgets';
			cr;
			nextPutAll: '----------------------';
			cr.

		stream
			nextPutAll: 'Token budget: ';
			nextPutAll: director tokenBudget asString;
			cr.

		stream
			nextPutAll: 'Cognitive load budget: ';
			nextPutAll: director cognitiveLoadBudget asString;
			cr.

		stream
			nextPutAll: 'Time budget: ';
			nextPutAll: director timeBudgetMinutes asString;
			nextPutAll: ' minutes';
			cr.

		stream
			nextPutAll: 'Message limit: ';
			nextPutAll: director messageLimit asString;
			cr.

		stream
			nextPutAll: 'Request timeout: ';
			nextPutAll: director requestTimeoutSeconds asString;
			nextPutAll: ' seconds';
			cr ]
]

{ #category : 'tools' }
ChatPharoThinkingDetailPresenter >> buildToolsSummary [
	"Build a formatted summary of executed tools"

	| tools |
	thinkingPresenter ifNil: [ ^ 'No data available.' ].
	tools := thinkingPresenter executedTools.

	tools ifEmpty: [ ^ 'No tools executed yet.' ].

	^ String streamContents: [ :stream |
		stream
			nextPutAll: 'Tools Executed (';
			nextPutAll: tools size asString;
			nextPutAll: ')';
			cr;
			nextPutAll: '======================';
			cr; cr.

		tools doWithIndex: [ :toolName :index |
			stream
				nextPutAll: index asString;
				nextPutAll: '. ';
				nextPutAll: toolName;
				cr ] ]
]

{ #category : 'layout' }
ChatPharoThinkingDetailPresenter >> defaultLayout [

	^ SpBoxLayout newVertical
		 spacing: 8;
		add: (SpBoxLayout newHorizontal
			spacing: 15;
			add: phaseLabel expand: false;
			add: elapsedLabel expand: false;
			add: modelLabel expand: true;
			yourself) expand: false;
		add: notebook;
		  add: closeButton expand: false;
		  yourself
]

{ #category : 'initialization' }
ChatPharoThinkingDetailPresenter >> initialize [

	super initialize.
	thinkingPresenter := nil.
]

{ #category : 'initialization' }
ChatPharoThinkingDetailPresenter >> initializePresenters [

	phaseLabel := self newLabel
		label: 'Phase: --';
		yourself.

	elapsedLabel := self newLabel
		label: 'Elapsed: --';
		yourself.

	modelLabel := self newLabel
		label: 'Model: --';
		yourself.

	toolsText := self newText
		editable: false;
		yourself.

	thinkingText := self newText
		editable: false;
		yourself.

	ethicsSummaryText := self newText
		editable: false;
		yourself.

	notebook := self newNotebook
		addPageTitle: 'Tools' provider: [ toolsText ];
		addPageTitle: 'Thinking' provider: [ thinkingText ];
		addPageTitle: 'Ethics Director' provider: [ ethicsSummaryText ];
		yourself.

	closeButton := self newButton
		label: 'Close';
		icon: (self iconNamed: #smallCancel);
		action: [ self window close ];
		yourself
]

{ #category : 'initialization' }
ChatPharoThinkingDetailPresenter >> initializeWindow: aWindowPresenter [

	aWindowPresenter
		title: 'Interaction Details';
		initialExtent: 700 @ 500
]

{ #category : 'initialization' }
ChatPharoThinkingDetailPresenter >> thinkingPresenter: aThinkingPresenter [
	"Set the thinking presenter to pull data from and update the display"

	thinkingPresenter := aThinkingPresenter.
	self updateDetails
]

{ #category : 'initialization' }
ChatPharoThinkingDetailPresenter >> updateDetails [
	"Refresh all displayed information from the thinking presenter"

	thinkingPresenter ifNil: [ ^ self ].

	phaseLabel label: 'Phase: ' , thinkingPresenter phaseText.

	elapsedLabel label: 'Elapsed: ' , thinkingPresenter formattedElapsedThinkingTime.

	modelLabel label: 'Model: ' , (thinkingPresenter modelNameText ifEmpty: [ 'Not selected' ]).

	toolsText text: self buildToolsSummary.

	thinkingText text: (thinkingPresenter thinkingContent ifEmpty: [ 'No thinking content available.' ]).

	ethicsSummaryText text: self buildEthicsSummary
]
