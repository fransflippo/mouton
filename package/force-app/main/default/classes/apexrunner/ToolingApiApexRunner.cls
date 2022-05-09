/**
 * ApexRunner implementation that uses the Salesforce Apex SOAP API to run anonymous Apex.
 * The current user's session ID is used to authenticate.
**/
public class ToolingApiApexRunner implements ApexRunner {

	private ToolingWebService.SforceService toolingWebService = new ToolingWebService.SforceService();
	
	public String executeAnonymous(String script) {
		// Set up web service to send the necessary request headers:
		// - Session header to run in the same session as this thread
		// - Debugging header to request debug logs (they will be returned in the DebuggingInfo response header)
		toolingWebService.SessionHeader = new ToolingWebService.SessionHeader_element();
		toolingWebService.SessionHeader.sessionId = UserInfo.getSessionId();
		toolingWebService.DebuggingHeader = new ToolingWebService.DebuggingHeader_element();
		toolingWebService.DebuggingHeader.debugLevel = 'NONE';
		toolingWebService.DebuggingHeader.categories = new ToolingWebService.LogInfo[1];
		toolingWebService.DebuggingHeader.categories[0] = new ToolingWebService.LogInfo();
		toolingWebService.DebuggingHeader.categories[0].category = 'Apex_code';
		toolingWebService.DebuggingHeader.categories[0].level = 'DEBUG';
		
		// Call the Tooling API
		System.debug(LoggingLevel.INFO, 'Calling Tooling API...');
		ToolingWebService.ExecuteAnonymousResult executeAnonymousResponse = toolingWebService.executeAnonymous(script);
		System.debug(LoggingLevel.INFO, 'Tooling API call returned');
		
		// Handle the response
		System.debug(executeAnonymousResponse);
		if (!executeAnonymousResponse.compiled) {
			throw new ApexCompilationException(
					executeAnonymousResponse.compileProblem, 
					executeAnonymousResponse.line, 
					executeAnonymousResponse.column);
		} else {
			// Get the debug logs from the DebugInfo response header
			String debugLog = toolingWebService.DebuggingInfo.debugLog;
			if (!executeAnonymousResponse.success) {
				throw new ApexExecutionException(
						executeAnonymousResponse.exceptionMessage, 
						executeAnonymousResponse.exceptionStackTrace, 
						executeAnonymousResponse.line, 
						executeAnonymousResponse.column, 
						debugLog);
			} else {
				return debugLog;
			}
		}
	}
}
