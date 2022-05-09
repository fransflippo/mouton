public class NewJobResource {

    /**
     * The type of job to create. One of:
     * - migrate : Migrates the schema to the latest version.
     * - baseline : Baselines an existing database, excluding all migrations up to and including baselineVersion.
     */
    public String type;
    
    // Properties for type = "baseline"
    public String baselineVersion;
    
}