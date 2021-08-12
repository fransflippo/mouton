/**
 * ApexRunner implementation that uses the Salesforce Apex SOAP API to run anonymous Apex.
 * The current user's session ID is used to authenticate.
**/
public class SoapApiApexRunner implements ApexRunner {

	public void executeAnonymous(String script) {
		String url = URL.getOrgDomainUrl().toExternalForm() + '/services/Soap/s/52.0';
		System.debug('SOAP endpoint is [' + url + ']');

		String sessionId = UserInfo.getSessionId();
		ApexSoapClient.Apex apex = new ApexSoapClient.Apex(url);
		apex.SessionHeader = new ApexSoapClient.SessionHeader_element();
		apex.SessionHeader.sessionId = sessionId;
		System.debug('Session ID is [' + sessionId + ']');
		apex.executeAnonymous(script);
		// TODO Return execution logs (executeAnonymousResponse_element.logs)
	}
}
