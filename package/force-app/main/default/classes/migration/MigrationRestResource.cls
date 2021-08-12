@RestResource(UrlMapping = '/migrations/*')
global with sharing class MigrationRestResource {

	@TestVisible
	private static MigrationService migrationService = new MigrationService();

	@HttpGet
	global static void doGet() {
		RestRequest req = RestContext.request;
		System.debug('requestURI = ' + req.requestURI);
		System.debug('resourcePath = ' + req.resourcePath);
		String uri = req.requestURI;
		if (uri.startsWith('/m7n')) {
			uri = uri.substring('/m7n'.length());
		}
		Integer firstSlash = uri.indexOf('/', 1);
		Integer secondSlash = -1;
		if (firstSlash != -1) {
			secondSlash = uri.indexOf('/', firstSlash + 1);
		}
		Integer thirdSlash = -1;
		if (secondSlash != -1) {
			thirdSlash = uri.indexOf('/', secondSlash + 1);
		}

		if (firstSlash == -1) {
			// Get packages
			List<String> packages = migrationService.getPackages();
			RestContext.response.responseBody = Blob.valueOf(JSON.serialize(packages));
			return;
		} else if (secondSlash == -1) {
			// Get migrations for package
			String packageName = uri.substring(firstSlash + 1);
			List<MigrationSummary> migrations = migrationService.findByPackageName(packageName, req.requestURI);
			RestContext.response.responseBody = Blob.valueOf(JSON.serialize(migrations));
			return;
		} else if (thirdSlash == -1) {
			// Get details for a single migration
			String packageName = uri.subString(firstSlash + 1, secondSlash);
			String versionString = uri.subString(secondSlash + 1);
			Integer version = Integer.valueOf(versionString);
			ExecutedMigration migration = migrationService.getMigration(packageName, version);
			RestContext.response.responseBody = Blob.valueOf(JSON.serialize(migration));
			return;
		} else {
			RestContext.response.statusCode = 404;
			return;
		}
	}

	@HttpPost
	global static List<MigrationSummary> doPost() {
		RestRequest req = RestContext.request;
		String uri = req.requestURI;
		if (uri.startsWith('/m7n')) {
			uri = uri.substring('/m7n'.length());
		}
		Integer firstSlash = uri.indexOf('/', 1);
		Integer secondSlash = -1;
		if (firstSlash != -1) {
			secondSlash = uri.indexOf('/', firstSlash + 1);
		}
		Integer thirdSlash = -1;
		if (secondSlash != -1) {
			thirdSlash = uri.indexOf('/', secondSlash + 1);
		}

		if (firstSlash == -1) {
			RestContext.response.statusCode = 404;
			return null;
		} else if (secondSlash == -1) {
			String packageName = uri.substring(firstSlash + 1);
			Migration migration = (Migration) System.JSON.deserialize(req.requestBody.toString(), Migration.class);
			migrationService.run(packageName, migration);
			return migrationService.findByPackageName(packageName, req.requestURI);
		} else {
			RestContext.response.statusCode = 404;
			return null;
		}
	}

}
