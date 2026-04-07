"
Settings presenter for managing ChatPharo applications.
Shows a list of available applications (MCP, Multivers, Skills, Memory, Custom Tools)
with activation checkboxes. Selecting an application shows its configuration panel.
"
Class {
	#name : 'ChatPharoApplicationSettingsPresenter',
	#superclass : 'SpPresenter',
	#instVars : [
		'model',
		'applicationList',
		'detailContainer',
		'detailPresenter',
		'applications'
	],
	#category : 'AI-ChatPharo-Spec-Core',
	#package : 'AI-ChatPharo-Spec',
	#tag : 'Core'
}

{ #category : 'initialization' }
ChatPharoApplicationSettingsPresenter >> applicationDefinitions [
	"Return an ordered collection of application definitions.
	 Each is a dictionary with keys: name, icon, enabledBlock, enableBlock, presenterBlock"

	^ OrderedCollection new
		add: (Dictionary new
			at: 'name' put: 'MCP';
			at: 'description' put: 'Model Context Protocol - connect to external tool servers';
			at: 'icon' put: #network;
			at: 'enabledBlock' put: [ model mcpEnabled ];
			at: 'enableBlock' put: [ :val | model mcpEnabled: val ];
			at: 'presenterBlock' put: [ ChatPharoMCPSettingsPresenter on: model ];
			yourself);
		add: (Dictionary new
			at: 'name' put: 'Multivers';
			at: 'description' put: 'Chain multiple agents in sequence for complex workflows';
			at: 'icon' put: #branch;
			at: 'enabledBlock' put: [ model multiversEnabled ];
			at: 'enableBlock' put: [ :val | model multiversEnabled: val ];
			at: 'presenterBlock' put: [ ChatPharoMultiversPresenter on: model ];
			yourself);
		add: (Dictionary new
			at: 'name' put: 'Skills';
			at: 'description' put: 'Manage skill files and automatic skill detection';
			at: 'icon' put: #smallObjects;
			at: 'enabledBlock' put: [ model skillToolsEnabled ];
			at: 'enableBlock' put: [ :val | model skillToolsEnabled: val ];
			at: 'presenterBlock' put: [ ChatPharoSkillsSettingsPresenter on: model ];
			yourself);
		add: (Dictionary new
			at: 'name' put: 'Memory';
			at: 'description' put: 'Long-term memory for conversation context';
			at: 'icon' put: #history;
			at: 'enabledBlock' put: [ model memoryEnabled ];
			at: 'enableBlock' put: [ :val | model memoryEnabled: val ];
			at: 'presenterBlock' put: [ ChatPharoMemoryPresenter on: model ];
			yourself);
		add: (Dictionary new
			at: 'name' put: 'Custom Tools';
			at: 'description' put: 'Define custom tools for the agent to use';
			at: 'icon' put: #smallObjects;
			at: 'enabledBlock' put: [ true ];
			at: 'enableBlock' put: [ :val | "Custom tools are always available" ];
			at: 'presenterBlock' put: [ ChatPharoCustomToolsSettingsPresenter on: model ];
			yourself);
		yourself
]

{ #category : 'initialization' }
ChatPharoApplicationSettingsPresenter >> connectPresenters [

	applicationList whenSelectedItemChangedDo: [ :item |
		item ifNotNil: [ self showDetailFor: item ] ]
]

{ #category : 'layout' }
ChatPharoApplicationSettingsPresenter >> defaultLayout [

	^ SpPanedLayout newLeftToRight
		positionOfSlider: 35 percent;
		add: (SpBoxLayout newTopToBottom
			spacing: 8;
			add: (self newLabel label: 'Applications') expand: false;
			add: applicationList;
			yourself);
		add: detailContainer;
		yourself
]

{ #category : 'initialization' }
ChatPharoApplicationSettingsPresenter >> initializePresenters [

	super initializePresenters.
	applications := self applicationDefinitions.

	applicationList := self newTable
		addColumn: (SpCheckBoxTableColumn new
			title: 'Active';
			width: 50;
			evaluated: [ :app | (app at: 'enabledBlock') value ];
			onActivation: [ :app | (app at: 'enableBlock') value: true ];
			onDeactivation: [ :app | (app at: 'enableBlock') value: false ];
			yourself);
		addColumn: (SpImageTableColumn new
			title: '';
			width: 24;
			evaluated: [ :app | self iconNamed: (app at: 'icon') ];
			yourself);
		addColumn: (SpStringTableColumn
			title: 'Application'
			evaluated: [ :app | app at: 'name' ]);
		items: applications;
		yourself.

	detailContainer := SpBoxLayout newTopToBottom
		spacing: 8;
		borderWidth: 8;
		add: (self newLabel label: 'Select an application to configure it.') expand: false;
		yourself
]

{ #category : 'accessing - model' }
ChatPharoApplicationSettingsPresenter >> setModelBeforeInitialization: aSettings [

	model := aSettings
]

{ #category : 'accessing - model' }
ChatPharoApplicationSettingsPresenter >> showDetailFor: anAppDefinition [
	"Show the configuration presenter for the selected application"

	| presenter headerLabel descLabel |
	headerLabel := self newLabel label: (anAppDefinition at: 'name').
	descLabel := self newLabel label: (anAppDefinition at: 'description').

	presenter := (anAppDefinition at: 'presenterBlock') value.

	self layout: (SpPanedLayout newLeftToRight
		positionOfSlider: 35 percent;
		add: (SpBoxLayout newTopToBottom
			spacing: 8;
			add: (self newLabel label: 'Applications') expand: false;
			add: applicationList;
			yourself);
		add: (SpBoxLayout newTopToBottom
			spacing: 6;
			borderWidth: 8;
			add: headerLabel expand: false;
			add: descLabel expand: false;
			add: presenter;
			yourself);
		yourself)
]
