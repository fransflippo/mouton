@RestResource(UrlMapping = '/jobs/*')
global with sharing class JobRestController {

	@TestVisible
	private static JobService jobService = new JobService();

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
		if (firstSlash == -1) {
			// /jobs only accepts POST requests
			RestContext.response.statusCode = 405;
			return;
		} else if (secondSlash != -1) {
			// /jobs/{id}/abc is not a valid URL for this REST controller (or any other)
			RestContext.response.statusCode = 404;
			return;
		}
		
		// Get details for a single job
		String jobId = uri.substring(firstSlash + 1);
		Job job = jobService.getJob(jobId);
		JobResource jobResource = convertToJobResource(job, req.requestURI.substring(0, firstSlash));
		RestContext.response.responseBody = Blob.valueOf(JSON.serialize(jobResource));
	}

	@HttpPost
	global static void doPost() {
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

		if (firstSlash != -1) {
			// /jobs/{id} only accepts GET requests
			RestContext.response.statusCode = 405;
			return;
		}
		if (secondSlash != -1) {
			// /jobs/{id}/abc is not a valid URL for this REST controller (or any other)
			RestContext.response.statusCode = 404;
			return;
		}
		
		NewJobResource newJobResource = (NewJobResource) System.JSON.deserialize(req.requestBody.toString(), NewJobResource.class);
		Job job = convertToJob(newJobResource);
		String jobId;
		try {
			jobId = jobService.saveJob(job);
		} catch (JobException e) {
			RestContext.response.statusCode = 422;  // Unprocessable Entity 
			RestContext.response.responseBody = Blob.valueOf(JSON.serialize(new ApiError(e.getMessage())));
			return;
		} catch (MigrationException e) {
			RestContext.response.statusCode = 500;  // Internal Server Error 
			RestContext.response.responseBody = Blob.valueOf(JSON.serialize(new ApiError(e.getMessage())));
			return;
		}
		job = jobService.getJob(jobId);
		JobResource jobResource = convertToJobResource(job, req.requestURI);
		RestContext.response.statusCode = 201;  // Created 
		RestContext.response.responseBody = Blob.valueOf(JSON.serialize(jobResource));
		RestContext.response.addHeader('Location', jobResource.url);
		return;
	}

	private static JobResource convertToJobResource(Job job, String baseUri) {
		JobResource jobResource = new JobResource();
		jobResource.id = job.id;
		jobResource.url = baseUri + job.id;
		jobResource.status = job.status.name();
		return jobResource;
	}

	private static Job convertToJob(NewJobResource newJobResource) {
		Job newJob;
		switch on (newJobResource.type) {
			when 'migrate' {
				newJob = new MigrateJob();
			}
			when 'baseline' {
				newJob = new BaselineJob();
			}
			when else {
				throw new IllegalArgumentException('Unknown job type "' + newJobResource.type + '"');
			}
		}
		newJob.status = Job.JobStatus.QUEUED;
		return newJob;
	}
	
}
