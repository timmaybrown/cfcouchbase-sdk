﻿/**
*********************************************************************************
* Copyright Since 2005 ColdBox Framework by Luis Majano and Ortus Solutions, Corp
* www.coldbox.org | www.luismajano.com | www.ortussolutions.com
********************************************************************************
* Base testing component to intergrate TestBox with ColdBox
*/
component extends="testbox.system.compat.framework.TestCase" accessors="true"{
	
	/**
	* The application mapping this test links to
	*/
	property name="appMapping";
	/**
	* The configuration location this test links to
	*/
	property name="configMapping";
	/**
	* The ColdBox controller this test links to
	*/
	property name="controller";
	/**
	* The application key for the ColdBox applicatin this test links to
	*/
	property name="coldboxAppKey";

	// Public Switch Properties
	this.loadColdbox = true;

	// Internal Properties
	variables.appMapping 	= "";
	variables.configMapping = "";
	variables.controller 	= "";
	variables.coldboxAppKey = "cbController";

	/********************************************* LIFE-CYCLE METHODS *********************************************/

	/**
	* Inspect test case for annotations
	* @return BaseTestCase
	*/
	function metadataInspection(){
		var md = getMetadata(this);
		// Inspect for appMapping annotation
		if( structKeyExists(md,"appMapping") ){
			variables.appMapping = md.appMapping;
		}
		// Configuration File mapping
		if( structKeyExists(md,"configMapping") ){
			variables.configMapping = md.configMapping;
		}
		// ColdBox App Key
		if( structKeyExists(md,"coldboxAppKey") ){
			variables.coldboxAppKey = md.coldboxAppKey;
		}
		// Load coldBox annotation
		if( structKeyExists(md,"loadColdbox") ){
			this.loadColdbox = md.loadColdbox;
		}
		return this;
	}

	/**
	* The main setup method for running ColdBox Integration enabled tests
	*/
	function beforeTests(){
		var appRootPath = "";
		var context		= "";

		// metadataInspection
		metadataInspection();

		// Load ColdBox Application for testing?
		if( this.loadColdbox ){
			// Check on Scope First
			if( structKeyExists(application,getColdboxAppKey()) ){
				variables.controller = application[getColdboxAppKey()];
			}
			else{
				// Verify App Root Path
				if( NOT len( variables.appMapping ) ){ variables.appMapping = "/"; }
				appRootPath = expandPath( variables.appMapping );
				// Clean the path for nice root path.
				if( NOT reFind( "(/|\\)$", appRootPath ) ){
					appRootPath = appRootPath & "/";
				}
				// Setup Coldbox configuration by convention
				if(NOT len( variables.configMapping ) ){
					if( len( variables.appMapping ) ){
						variables.configMapping = variables.appMapping & ".config.Coldbox";
					}
					else{
						variables.configMapping = "config.Coldbox";
					}
				}
				//Initialize mock Controller
				variables.controller = CreateObject("component", "coldbox.system.testing.mock.web.MockController").init( appRootPath=appRootPath, appKey=variables.coldboxAppKey );
				// persist for mock testing in right name
				application[ getColdboxAppKey() ] = variables.controller;
				// Setup
				variables.controller.getLoaderService().loadApplication( variables.configMapping, variables.appMapping );
			}
			// Auto registration of test as interceptor
			variables.controller.getInterceptorService().registerInterceptor(interceptorObject=this);
		}
	}

	/**
	* This executes before any test method for integration tests
	*/
	function setup(){
		// Are we doing integration tests
		if( this.loadColdbox ){
			// verify ColdBox still exists, else load it again:
			if( !structKeyExists( application, getColdboxAppKey() ) ){
				beforeTests();
			}
			// remove context
			getController().getRequestService().removeContext();
		}
	}

	/**
	* xUnit: The main teardown for ColdBox enabled applications after all tests execute
	*/
	function afterTests(){
		structDelete( application, getColdboxAppKey() );
	}

	/**
	* BDD: The main setup method for running ColdBox Integration enabled tests
	*/
	function beforeAll(){
		beforeTests();
	}

	/**
	* BDD: The main teardown for ColdBox enabled applications after all tests execute
	*/
	function afterAll(){
		afterTests();
	}

	/**
	* Reset the persistence of the unit test coldbox app, basically removes the controller from application scope
	* @return BaseTestCase
	*/
	function reset( boolean clearMethods=false, decorator ){
		structDelete( application, getColdboxAppKey() );
		structClear( request );
		return this;
	}

	/********************************************* MOCKING METHODS *********************************************/

	/**
	* I will return to you a mock request buffer object used mostly in interceptor calls
	* @return coldbox.system.core.util.RequestBuffer
	*/
	function getMockRequestBuffer(){
		return getMockBox().createMock("coldbox.system.core.util.RequestBuffer").init();
	}

	/**
	* I will return a mock controller object
	* @return coldbox.system.testing.mock.web.MockController
	*/
	function getMockController(){
		return CreateObject("component", "coldbox.system.testing.mock.web.MockController").init( '/unittest', 'unitTest' );
	}

	/**
	* Builds an empty functioning request context mocked with methods via MockBox.  You can also optionally wipe all methods on it
	* @clearMethods Clear methods on the object
	* @decorator The class path to the decorator to build into the mock request context
	* 
	* @return coldbox.system.web.context.RequestContext
	*/
	function getMockRequestContext( boolean clearMethods=false, decorator ){
		var mockRC 			= "";
		var mockController 	= "";
		var rcProps 		= structnew();

		if( arguments.clearMethods ){
			if( structKeyExists(arguments,"decorator") ){
				return getMockBox().createEmptyMock(arguments.decorator);
			}
			return getMockBox().createEmptyMock("coldbox.system.web.context.RequestContext");
		}

		// Create functioning request context
		mockRC 			= getMockBox().createMock("coldbox.system.web.context.RequestContext");
		mockController = CreateObject("component", "coldbox.system.testing.mock.web.MockController").init('/unittest','unitTest');

		// Create mock properties
		rcProps.DefaultLayout = "";
		rcProps.DefaultView = "";
		rcProps.isSES = false;
		rcProps.sesBaseURL = "";
		rcProps.eventName = "event";
		rcProps.ViewLayouts = structnew();
		rcProps.FolderLayouts = structnew();
		rcProps.RegisteredLayouts = structnew();
		rcProps.modules = structnew();
		mockRC.init( properties=rcProps, controller=mockController );

		// return decorator context
		if( structKeyExists(arguments,"decorator") ){
			return getMockBox().createMock(arguments.decorator).init(mockRC, mockController);
		}

		// return normal RC
		return mockRC;
	}

	/**
	* ColdBox must be loaded for this to work. Get a mock model object by convention. You can optional clear all the methods on the model object if you wanted to. The object is created but not initiated, that would be your job.
	* @name The name of the model to mock and return back
	* @clearMethods Clear methods on the object
	*/
	function getMockModel( required name, boolean clearMethods=false ){
		var mockLocation = getController().getWireBox().locateInstance( arguments.name );

		if( len( mockLocation ) ){
			return getMockBox().createMock( className=mockLocation, clearMethods=arguments.clearMethods );
		}
		else{
			throw( message="Model object #arguments.name# could not be located.", type="ModelNotFoundException" );
		}
	}

	/********************************************* APP RETRIEVAL METHODS *********************************************/
	
	/**
	* Get the WireBox reference from the running application
	* @return coldbox.system.ioc.Injector
	*/
	function getWireBox(){
		return variables.controller.getwireBox();
	}

	/**
	* Get the CacheBox reference from the running application
	* @return coldbox.system.cache.CacheFactory
	*/
	function getCacheBox(){
		return variables.controller.getCacheBox();
	}

	/**
	* Get the CacheBox reference from the running application
	* @cacheName The cache name to retrieve or returns the 'default' cache by default.
	* 
	* @return coldbox.system.cache.ICacheProvider
	*/
	function getCache( required cacheName="default" ){
		return getController().getCache( arguments.cacheName );
	}

	/**
	* Get the LogBox reference from the running application
	* @return coldbox.system.logging.LogBox
	*/
	function getLogBox(){
		return variables.controller.getLogBox();
	}

	/**
	* Get the RequestContext reference from the running application
	* 
	* @return coldbox.system.web.context.RequestContext
	*/
	function getRequestContext(){
		return getController().getRequestService().getContext();
	}

	/**
	* Get the RequestContext reference from the running application
	* 
	* @return coldbox.system.web.Flash.AbstractFlashScope
	*/
	function getFlashScope(){
		return getController().getRequestService().getFlashScope();
	}

	/********************************************* APPLICATION EXECUTION METHODS *********************************************/

	/**
	* Setup an initial request capture.  I basically look at the FORM/URL scopes and create the request collection out of them.
	* @event The event to setup the request context with, simulates the URL/FORM.event
	* 
	* @return BaseTestCase
	*/
	function setupRequest( required event ){
		// Setup the incoming event
		URL[getController().getSetting("EventName")] = arguments.event;
		// Capture the request
		getController().getRequestService().requestCapture();
		return this;
	}

	/**
	* Executes a framework lifecycle by executing an event.  This method returns a request context object that can be used for assertions
	* @event The event to execute
	* @private Call a private event or not
	* @prePostExempt If true, pre/post handlers will not be fired.
	* @eventArguments A collection of arguments to passthrough to the calling event handler method
	* @renderResults If true, then it will try to do the normal rendering procedures and store the rendered content in the RC as cbox_rendered_content
	* 
	* @return coldbox.system.context.RequestContext
	*/
	function execute(
		required event,
		boolean private=false,
		boolean prePostExempt=false,
		struct eventArguments={},
		boolean renderResults=false
	){
		var handlerResults  = "";
		var requestContext  = "";
		var relocationTypes = "TestController.setNextEvent,TestController.relocate";
		var cbController    = getController();
		var renderData		= "";
		var renderedContent = "";
		var iData			= {};

		//Setup the request Context with setup FORM/URL variables set in the unit test.
		setupRequest(arguments.event);

		try{

			// App Start Handler
			if ( len(cbController.getSetting("ApplicationStartHandler")) ){
				cbController.runEvent(cbController.getSetting("ApplicationStartHandler"),true);
			}
			// preProcess
			cbController.getInterceptorService().processState("preProcess");
			// Request Start Handler
			if ( len(cbController.getSetting("RequestStartHandler")) ){
				cbController.runEvent(cbController.getSetting("RequestStartHandler"),true);
			}

			// grab the latest event in the context, in case overrides occur
			requestContext  = getRequestContext();
			arguments.event = requestContext.getCurrentEvent();

			// TEST EVENT EXECUTION
			if( NOT requestContext.isNoExecution() ){
				// execute the event
				handlerResults = cbController.runEvent(event=arguments.event,
												   private=arguments.private,
												   prepostExempt=arguments.prepostExempt,
												   eventArguments=arguments.eventArguments);

				// Are we doing rendering procedures?
				if( arguments.renderResults ){
					// preLayout
					cbController.getInterceptorService().processState("preLayout");

					// Render Data?
					renderData = requestContext.getRenderData();
					if( isStruct( renderData ) and NOT structIsEmpty( renderData ) ){
						renderedContent = cbController.getDataMarshaller().marshallData(argumentCollection=renderData);
					}
					// If we have handler results save them in our context for assertions
					else if ( isDefined("handlerResults") ){
						requestContext.setValue("cbox_handler_results", handlerResults);
						renderedContent = handlerResults;
					}
					// render layout/view pair
					else{
						renderedContent = cbcontroller.getRenderer()
							.renderLayout(module=requestContext.getCurrentLayoutModule(),
									     viewModule=requestContext.getCurrentViewModule());
					}

					// Pre Render
					iData = { renderedContent = renderedContent };
					cbController.getInterceptorService().processState("preRender", iData);
					renderedContent = iData.renderedContent;

					// Store in collection for assertions
					requestContext.setValue( "cbox_rendered_content", renderedContent );

					// postRender
					cbController.getInterceptorService().processState("postRender");
				}
			}

			// Request End Handler
			if ( len(cbController.getSetting("RequestEndHandler")) ){
				cbController.runEvent( cbController.getSetting("RequestEndHandler"), true );
			}

			// postProcess
			cbController.getInterceptorService().processState("postProcess");

		}
		catch(Any e){
			// Exclude relocations so they can be asserted.
			if( NOT listFindNoCase(relocationTypes,e.type) ){
				rethrow;
			}
		}

		// Return the correct event context.
		requestContext = getRequestContext();

		return requestContext;
	}


	/**
	* Announce an interception to the system. If you use the asynchronous facilities, you will get a thread structure report as a result.
	* @state.hint The event to announce
	* @interceptData.hint A data structure used to pass intercepted information.
	* @async.hint If true, the entire interception chain will be ran in a separate thread.
	* @asyncAll.hint If true, each interceptor in the interception chain will be ran in a separate thread and then joined together at the end.
	* @asyncAllJoin.hint If true, each interceptor in the interception chain will be ran in a separate thread and joined together at the end by default.  If you set this flag to false then there will be no joining and waiting for the threads to finalize.
	* @asyncPriority.hint The thread priority to be used. Either LOW, NORMAL or HIGH. The default value is NORMAL
	* @asyncJoinTimeout.hint The timeout in milliseconds for the join thread to wait for interceptor threads to finish.  By default there is no timeout.
	*
	* @return struct of thread information or void
	*/
	function announceInterception(
		required state,
		struct interceptData={},
		boolean async=false,
		boolean asyncAll=false,
		boolean asyncAllJoin=true,
		asyncPriority="NORMAL",
		numeric asyncJoinTimeout=0
	){
		return getController().getInterceptorService().processState( argumentCollection=arguments );
	}

	/**
	* Get an interceptor reference
	* @interceptorName.hint The name of the interceptor to retrieve
	*
	* @return Interceptor
	*/
	function getInterceptor( required interceptorName ){
		return getController().getInterceptorService().getInterceptor( argumentCollection=arguments );
	}

	/**
	* Get a model object
	* @name.hint The mapping name or CFC path to retrieve
	* @dsl.hint The DSL string to use to retrieve an instance
	* @initArguments.hint The constructor structure of arguments to passthrough when initializing the instance
	*/
	function getModel( name, dsl, initArguments={} ){
		return getInstance( argumentCollection=arguments );
	}

	/**
	* Get a instance object from WireBox
	* @name.hint The mapping name or CFC path to retrieve
	* @dsl.hint The DSL string to use to retrieve an instance
	* @initArguments.hint The constructor structure of arguments to passthrough when initializing the instance
	*/
	function getInstance( name, dsl, initArguments={} ){
		return getController().getWireBox().getInstance( argumentCollection=arguments );
	}

	/**
	* Get the ColdBox global utility class
	*/
	function getUtil(){
		return new coldbox.system.core.util.Util();
	}

}