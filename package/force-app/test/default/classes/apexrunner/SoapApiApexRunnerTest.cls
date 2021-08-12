@IsTest
public class SoapApiApexRunnerTest {

	private static SoapApiApexRunner apexRunner = new SoapApiApexRunner();

	public class WebServiceInvocation {
		Object stub;
		Object request;
		Map<String, Object> responseMap;
		String endpoint;
		String soapAction;
		String requestName;
		String responseNS;
		String responseName;
		String responseType;
	}

	public class ApexSoapApiWebServiceMock implements WebServiceMock {

		public List<WebServiceInvocation> webServiceInvocations = new List<WebServiceInvocation>();

		private final Object response;

		public ApexSoapApiWebServiceMock(Object response) {
			this.response = response;
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
			webServiceInvocation.stub = stub;
			webServiceInvocation.request = request;
			webServiceInvocation.responseMap = responseMap;
			webServiceInvocation.endpoint = endpoint;
			webServiceInvocation.soapAction = soapAction;
			webServiceInvocation.requestName = requestName;
			webServiceInvocation.responseNS = responseNS;
			webServiceInvocation.responseName = responseName;
			webServiceInvocation.responseType = responseType;
			webServiceInvocations.add(webServiceInvocation);

			responseMap.put('response_x', response);
		}
	}

	@IsTest
	public static void testExecuteAnonymous() {
		// Given
		String apexScript = 'System.debug([SELECT Id FROM User]);';
		ApexSoapClient.executeAnonymousResponse_element response = new ApexSoapClient.executeAnonymousResponse_element();
		response.result = new ApexSoapClient.ExecuteAnonymousResult();
		response.result.success = true;
		response.result.compiled = true;
		ApexSoapApiWebServiceMock webServiceMock = new ApexSoapApiWebServiceMock(response);
		Test.setMock(WebServiceMock.class, webServiceMock);

		// When
		apexRunner.executeAnonymous(apexScript);

		// Then
		System.assertEquals(1, webServiceMock.webServiceInvocations.size());
		WebServiceInvocation webServiceInvocation = webServiceMock.webServiceInvocations[0];
		ApexSoapClient.executeAnonymous_element request = (ApexSoapClient.executeAnonymous_element) webServiceInvocation.request;
		System.assertEquals(apexScript, request.String_x);
	}

	@IsTest
	public static void testExecuteAnonymous_compileError() {
		// Given
		String apexScript = 'System.debug(';
		ApexSoapClient.executeAnonymousResponse_element response = new ApexSoapClient.executeAnonymousResponse_element();
		response.result = new ApexSoapClient.ExecuteAnonymousResult();
		response.result.success = false;
		response.result.compiled = false;
        response.result.compileProblem = 'Unexpected token \'(\'.';
        response.result.exceptionMessage = '';
        response.result.exceptionStackTrace = '';
        response.result.line = 1;
        response.result.column = 13;
		ApexSoapApiWebServiceMock webServiceMock = new ApexSoapApiWebServiceMock(response);
		Test.setMock(WebServiceMock.class, webServiceMock);

		// When
		try {
			apexRunner.executeAnonymous(apexScript);
			System.assert(false, 'Expected ApexCompilationException');
		} catch (ApexCompilationException e) {
		}

		// Then
		System.assertEquals(1, webServiceMock.webServiceInvocations.size());
		WebServiceInvocation webServiceInvocation = webServiceMock.webServiceInvocations[0];
		ApexSoapClient.executeAnonymous_element request = (ApexSoapClient.executeAnonymous_element) webServiceInvocation.request;
		System.assertEquals(apexScript, request.String_x);
	}

	@IsTest
	public static void testExecuteAnonymous_executionError() {
		// Given
		String apexScript = 'String s; System.debug(s.length());';
		ApexSoapClient.executeAnonymousResponse_element response = new ApexSoapClient.executeAnonymousResponse_element();
		response.result = new ApexSoapClient.ExecuteAnonymousResult();
		response.result.success = false;
		response.result.compiled = true;
        response.result.compileProblem = '';
        response.result.exceptionMessage = '"System.NullPointerException: Attempt to de-reference a null object';
        response.result.exceptionStackTrace = 'AnonymousBlock: line 1, column 1';
        response.result.line = 1;
        response.result.column = 1;
		ApexSoapApiWebServiceMock webServiceMock = new ApexSoapApiWebServiceMock(response);
		Test.setMock(WebServiceMock.class, webServiceMock);

		// When
		try {
			apexRunner.executeAnonymous(apexScript);
			System.assert(false, 'Expected ApexExecutionException');
		} catch (ApexExecutionException e) {
		}

		// Then
		System.assertEquals(1, webServiceMock.webServiceInvocations.size());
		WebServiceInvocation webServiceInvocation = webServiceMock.webServiceInvocations[0];
		ApexSoapClient.executeAnonymous_element request = (ApexSoapClient.executeAnonymous_element) webServiceInvocation.request;
		System.assertEquals(apexScript, request.String_x);
	}
}