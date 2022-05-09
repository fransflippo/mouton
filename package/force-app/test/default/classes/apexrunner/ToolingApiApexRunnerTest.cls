@IsTest
public class ToolingApiApexRunnerTest {

	private static ToolingApiApexRunner apexRunner = new ToolingApiApexRunner();

	public class WebServiceInvocation {
		ToolingWebService.SforceService stub;
		Object request;
		Map<String, Object> responseMap;
		String endpoint;
		String soapAction;
		String requestName;
		String responseNS;
		String responseName;
		String responseType;
	}

	public class ToolingWebServiceMock implements WebServiceMock {

		public List<WebServiceInvocation> webServiceInvocations = new List<WebServiceInvocation>();

		private final Object response;
		private final InvokeHandler invokeHandler;

		public ToolingWebServiceMock(Object response, InvokeHandler invokeHandler) {
			this.response = response;
			this.invokeHandler = invokeHandler;
		}

		public void doInvoke(
				Object stub,
				Object request,
				Map<String, Object> responseMap,
				String endpoint,
				String soapAction,
				String requestName,
				String responseNS,
				String responseName,
				String responseType
		) {
			WebServiceInvocation webServiceInvocation = new WebServiceInvocation();
			webServiceInvocation.stub = (ToolingWebService.SforceService)stub;
			webServiceInvocation.request = request;
			webServiceInvocation.responseMap = responseMap;
			webServiceInvocation.endpoint = endpoint;
			webServiceInvocation.soapAction = soapAction;
			webServiceInvocation.requestName = requestName;
			webServiceInvocation.responseNS = responseNS;
			webServiceInvocation.responseName = responseName;
			webServiceInvocation.responseType = responseType;
			webServiceInvocations.add(webServiceInvocation);
			invokeHandler.onInvoke(webServiceInvocation);
			responseMap.put('response_x', response);
		}
	}
	
	public interface InvokeHandler {
		void onInvoke(WebServiceInvocation webServiceInvocation);
	}

	public class AddDebugResponseInvokeHandler implements InvokeHandler {

		public void onInvoke(WebServiceInvocation invocation) {
			invocation.stub.DebuggingInfo = new ToolingWebService.DebuggingInfo_element();
			invocation.stub.DebuggingInfo.debugLog = 'Log output';
		}
	}
	
	@IsTest
	public static void testExecuteAnonymous() {
		// Given
		String apexScript = 'System.debug([SELECT Username FROM User]);';
		ToolingWebService.executeAnonymousResponse_element response = new ToolingWebService.executeAnonymousResponse_element();
		response.result = new ToolingWebService.ExecuteAnonymousResult();
		response.result.success = true;
		response.result.compiled = true;
		ToolingWebServiceMock webServiceMock = new ToolingWebServiceMock(response, new AddDebugResponseInvokeHandler());
		Test.setMock(WebServiceMock.class, webServiceMock);

		// When
		String logs = apexRunner.executeAnonymous(apexScript);

		// Then
		System.assertEquals(1, webServiceMock.webServiceInvocations.size());
		WebServiceInvocation webServiceInvocation = webServiceMock.webServiceInvocations[0];
		ToolingWebService.executeAnonymous_element request = (ToolingWebService.executeAnonymous_element) webServiceInvocation.request;
		System.assertEquals(apexScript, request.String_x);
		System.assertEquals('Log output', logs);
	}

	@IsTest
	public static void testExecuteAnonymous_compileError() {
		// Given
		String apexScript = 'System.debug(';
		ToolingWebService.executeAnonymousResponse_element response = new ToolingWebService.executeAnonymousResponse_element();
		response.result = new ToolingWebService.ExecuteAnonymousResult();
		response.result.success = false;
		response.result.compiled = false;
        response.result.compileProblem = 'Unexpected token \'(\'.';
        response.result.exceptionMessage = '';
        response.result.exceptionStackTrace = '';
        response.result.line = 1;
        response.result.column = 13;
		ToolingWebServiceMock webServiceMock = new ToolingWebServiceMock(response, new AddDebugResponseInvokeHandler());
		Test.setMock(WebServiceMock.class, webServiceMock);

		// When
		try {
			apexRunner.executeAnonymous(apexScript);
			System.assert(false, 'Expected ApexCompilationException');
		} catch (ApexCompilationException e) {
			System.assertEquals(1, e.line);
			System.assertEquals(13, e.column);
			System.assertEquals('Unexpected token \'(\'.', e.compileProblem);
		}

		// Then
		System.assertEquals(1, webServiceMock.webServiceInvocations.size());
		WebServiceInvocation webServiceInvocation = webServiceMock.webServiceInvocations[0];
		ToolingWebService.executeAnonymous_element request = (ToolingWebService.executeAnonymous_element) webServiceInvocation.request;
		System.assertEquals(apexScript, request.String_x);
		
	}

	@IsTest
	public static void testExecuteAnonymous_executionError() {
		// Given
		String apexScript = 'String s; System.debug(s.length());';
		ToolingWebService.executeAnonymousResponse_element response = new ToolingWebService.executeAnonymousResponse_element();
		response.result = new ToolingWebService.ExecuteAnonymousResult();
		response.result.success = false;
		response.result.compiled = true;
        response.result.compileProblem = '';
        response.result.exceptionMessage = '"System.NullPointerException: Attempt to de-reference a null object';
        response.result.exceptionStackTrace = 'AnonymousBlock: line 1, column 1';
        response.result.line = 1;
        response.result.column = 1;
		ToolingWebServiceMock webServiceMock = new ToolingWebServiceMock(response, new AddDebugResponseInvokeHandler());
		Test.setMock(WebServiceMock.class, webServiceMock);

		// When
		try {
			apexRunner.executeAnonymous(apexScript);
			System.assert(false, 'Expected ApexExecutionException');
		} catch (ApexExecutionException e) {
			System.assertEquals(1, e.line);
			System.assertEquals(1, e.column);
			System.assertEquals('"System.NullPointerException: Attempt to de-reference a null object', e.exceptionMessage);
			System.assertEquals('AnonymousBlock: line 1, column 1', e.exceptionStackTrace);
			System.assertEquals('Log output', e.debugLog);
		}

		// Then
		System.assertEquals(1, webServiceMock.webServiceInvocations.size());
		WebServiceInvocation webServiceInvocation = webServiceMock.webServiceInvocations[0];
		ToolingWebService.executeAnonymous_element request = (ToolingWebService.executeAnonymous_element) webServiceInvocation.request;
		System.assertEquals(apexScript, request.String_x);
	}
}