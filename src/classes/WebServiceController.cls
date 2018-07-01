public with sharing class WebServiceController {

	private final String BASE_URL = 'https://login.salesforce.com/services/oauth2';
	WebServiceEndpoint__c endpoint = WebServiceEndpoint__c.getOrgDefaults();

	public WebServiceController() {}

	public void init() {
		if (ApexPages.currentPage().getParameters().containsKey('code')) {
			//HTTPS to get token
			HttpRequest request = new HttpRequest();
			request.setEndpoint(BASE_URL + '/token');
			request.setMethod('POST');

			List<String> paramters = new List<String> {
				'grant_type=authorization_code',
				'code=' + ApexPages.currentPage().getParameters().get('code'),
				'client_id=' + endpoint.ClientId__c,
				'client_secret=' + endpoint.ClientSecret__c,
				'redirect_uri=' + endpoint.Callback__c
			};
			request.setBody(String.join(paramters, '&'));

			HttpResponse response = new Http().send(request);
			Map<String, Object> params = (Map<String, Object>)JSON.deserializeUntyped(response.getBody());

			endpoint.AccessToken__c = String.valueOf(params.get('access_token'));
			endpoint.RefreshToken__c = String.valueOf(params.get('refresh_token'));
			update endpoint;
		}
	}

	public PageReference doAuthenticate() {


		PageReference redirect = new PageReference(BASE_URL + '/authorize');
		redirect.getParameters().put('response_type','code');
		redirect.getParameters().put('client_id', endpoint.ClientId__c);
		redirect.getParameters().put('redirect_uri',endpoint.Callback__c);
		redirect.setRedirect(true);

		return redirect;
	}

	public void bookFlight() {
		HttpRequest request = new HttpRequest();
		request.setEndpoint('https://ap5.salesforce.com/services/apexrest/book_flight');
		request.setMethod('POST');
		request.setHeader('Content-Type', 'application/json');
		request.setHeader('Authorization', 'OAuth ' + endpoint.AccessToken__c);
		request.setBody('{"dateFrom": "2018-07-01", "dateTo": "2018-07-10"}');

		HttpResponse response = new Http().send(request);
		ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, response.getBody()));
	}
}