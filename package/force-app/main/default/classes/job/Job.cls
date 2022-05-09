public abstract class Job {
    
    public enum JobStatus {
        QUEUED,
        RUNNING,
        FAILED,
        COMPLETED
    }

    /**
     * The job's unique identifier
     */
    public String id;
    
    public JobStatus status;

    /**
     * Returns a Queueable that can be queued and that will run the job
     * @return A queueable that will run the job
     */
    public abstract Queueable toQueueable();

}