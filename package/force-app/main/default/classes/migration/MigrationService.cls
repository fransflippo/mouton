public with sharing class MigrationService {

    @TestVisible
    private MigrationSelector migrationSelector = new MigrationSelector();
    
	@TestVisible
	private ApexRunner apexRunner = new ToolingApiApexRunner();

	@TestVisible
	private Clock theClock = Clock.system();

	/**
	 * Returns a list of all packages that have saved migrations.
	 * @return a list of all packages that have saved migrations
	**/
	public List<String> getPackages() {
        return migrationSelector.selectUniquePackages();
	}

	/**
	 * Returns summaries of all saved migrations in the package specified. The migration are returned ordered by
	 * version, oldest first.
	 * @param packageName the package name to find migrations for
	 * @param baseUri the base URI to be used when constructing a URL link for the migration
	 * @return the list of migration summaries
	**/
	public List<MigrationSummary> findSummariesByPackageName(String packageName, String baseUri) {
		List<Migration__c> migrationEntities = migrationSelector.selectMigrationsByPackageName(packageName);
		List<MigrationSummary> migrations = new List<MigrationSummary>();
		for (Migration__c migrationEntity : migrationEntities) {
			MigrationSummary migration = new MigrationSummary(migrationEntity.Version__c.intValue(), migrationEntity.Script__c, migrationEntity.Checksum__c.intValue());
			migration.url = baseUri + '/' + migrationEntity.Version__c;
			migrations.add(migration);
		}
		return migrations;
	}

	/**
	 * Runs the given migration against the package specified.
	 * If the migration already exists and the description and checksum of the saved migration match the migration being
	 * submitted, this method returns without doing anything.
	 * If the migration already exists and the description and/or checksum of the saved migration do not match the
	 * migration being submitted, a MigrationException is thrown and the migration is not run nor saved to the database.
	 * @param packageName the name of the package that the migration will belong to
	 * @param migration the migration to save
	 * @return the unique identifier assigned to the migration
	**/
	public Id runMigration(String packageName, MigrationDefinition migration) {
		Migration__c migrationEntity = new Migration__c(
				Package__c = packageName,
				Version__c = migration.version,
				Checksum__c = migration.checksum,
				Description__c = migration.description,
				Installed_On__c = theClock.now(),
				Script__c = migration.scriptName,
				Type__c = migration.type.name()
		);
		Database.SaveResult saveResult = Database.insert(migrationEntity, false);
		if (saveResult.isSuccess()) {
		    return saveResult.getId();
		} else {
			Database.DuplicateError duplicateError = null;
			Boolean onlyDuplicateErrors = true;
			String errorMessage = null;
			for (Database.Error error : saveResult.getErrors()) {
				if (error instanceof Database.DuplicateError) {
					duplicateError = (Database.DuplicateError) error;
				} else {
					errorMessage = error.getMessage();
					onlyDuplicateErrors = false;
				}
			}
			if (errorMessage != null) {
				throw new MigrationException('Saving migration ' + migration.scriptName + ' failed: ' + errorMessage);
			}

			// We have an existing migration. If it has the same script name and checksum, that's fine, ignore it.
			// If it has a different description or checksum, report it
			Datacloud.DuplicateResult duplicateResult = duplicateError.getDuplicateResult();
			Datacloud.MatchResult matchResult = duplicateResult.getMatchResults()[0];
			Datacloud.MatchRecord matchRecord = matchResult.getMatchRecords()[0];
			Id existingMigrationId = matchRecord.getRecord().Id;
			Migration existingMigration =  getMigrationByPackageAndId(packageName, existingMigrationId);
			if (existingMigration.description != migration.description) {
				throw new DuplicateMigrationException('Migration with version ' + migration.version + ' has changed: old description is "' + existingMigration.description + '", new description is "' + migration.description + '"');
			}
			if (existingMigration.checksum != migration.checksum) {
				throw new DuplicateMigrationException('Migration with version ' + migration.version + ' has changed: old checksum is ' + existingMigration.checksum + ', new checksum is ' + migration.checksum);
			}

			// Queue the migration
			
			return existingMigrationId;
		}
	}

	/**
	 * Returns the details of a saved migration
	 * @return the saved migration
	**/
	public Migration getMigration(String packageName, Integer version) {
        List<Migration> migrations = getMigrations(packageName, new List<Integer> { version });
        return (migrations.isEmpty() ? null : migrations[0]);
	}

	/**
     * Returns the details of one or more saved migrations in the same package
     * @return the saved migration
    **/
	public List<Migration> getMigrations(String packageName, List<Integer> versions) {
        List<Migration__c> migrationEntities = migrationSelector.selectMigrationsByPackageNameAndVersion(packageName, versions);
        List<Migration> migrations = new List<Migration>();
        for (Migration__c migrationEntity : migrationEntities) {
            Migration migration = new Migration();
            migration.description = migrationEntity.Description__c;
            migration.installedOn = migrationEntity.Installed_On__c;
            migration.script = migrationEntity.Script__c;
            migration.type = toType(migrationEntity.Type__c);
            migration.version = migrationEntity.Version__c.intValue();
            migration.checksum = migrationEntity.Checksum__c.intValue();
            migrations.add(migration);
        }
        return migrations;
	}

	public void markFailed(Id migrationId, String errorMessage) {
		Migration__c migrationEntity = new Migration__c(Id = migrationId, Status__c = 'Failed');
		update migrationEntity;
	}

	public void markCompleted(Id migrationId) {
		Migration__c migrationEntity = new Migration__c(Id = migrationId, Status__c = 'Success');
		update migrationEntity;
	}
	
    // Private methods
    
    private Migration getMigrationByPackageAndId(String packageName, Id id) {
		List<Migration__c> migrationEntities = migrationSelector.selectMigrationsByPackageNameAndId(packageName, new List<Id> { id });
        if (migrationEntities.isEmpty()) {
            return null;
        }
        Migration__c migrationEntity = migrationEntities[0];
		Migration migration = new Migration();
		migration.description = migrationEntity.Description__c;
		migration.installedOn = migrationEntity.Installed_On__c;
		migration.script = migrationEntity.Script__c;
		migration.type = toType(migrationEntity.Type__c);
		migration.version = migrationEntity.Version__c.intValue();
		migration.checksum = migrationEntity.Checksum__c.intValue();
		return migration;
	}

	private MigrationDefinition.Type toType(String s) {
		if (s == 'APEX') {
			return MigrationDefinition.Type.APEX;
		}
		throw new IllegalArgumentException('Unknown migration type "' + s + '"');
	}

}
