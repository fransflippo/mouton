public with sharing class JobService {

    public Job getJob(String jobId) {
        return null;
    }

    public String saveJob(Job job) {
        Queueable queueable = job.toQueueable();
        Id jobId = System.enqueueJob(queueable);
        return jobId;
    }

}