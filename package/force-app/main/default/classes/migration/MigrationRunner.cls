public class MigrationRunner implements Queueable {

    private final ApexRunner apexRunner;
    private Id migrationId;
    private String data;
    private MigrationService migrationService;

    public MigrationRunner(Id migrationId, String data, ApexRunner apexRunner, MigrationService migrationService) {
        this.migrationId = migrationId;
        this.data = data;
        this.apexRunner = apexRunner;
        this.migrationService = migrationService;
    }
    
    public void execute(QueueableContext context) {
        try {
            apexRunner.executeAnonymous(data);
        } catch (ApexCompilationException e) {
            migrationService.markFailed(migrationId, e.compileProblem);
            return;
        } catch (ApexExecutionException e) {
            migrationService.markFailed(migrationId. e.exceptionMessage);
            return;
        }
        migrationService.markCompleted(migrationId);
    }
}