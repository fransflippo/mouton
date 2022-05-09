public class MigrateJob extends Job {

    public override Queueable toQueueable() {
        return new MigrationRunner(migrationId, data, apexRunner, migrationService);
    }
}