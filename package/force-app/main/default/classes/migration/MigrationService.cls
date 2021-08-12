public with sharing class MigrationService {

	@TestVisible
	private ApexRunner apexRunner = new SoapApiApexRunner();

	@TestVisible
	private Clock theClock = Clock.system();

	/**
	 * @description
	 * Returns a list of all packages that have saved migrations.
	**/
	public List<String> getPackages() {
		List<AggregateResult> migrations = [ SELECT Package__c FROM Migration__c GROUP BY Package__c ];
		List<String> packages = new List<String>();
		for (AggregateResult migration : migrations) {
			packages.add((String) migration.get('m7n__Package__c'));
		}
		return packages;
	}

	/**
	 * @description
	 * Returns summaries of all saved migrations in the package specified.
	**/
	public List<MigrationSummary> findByPackageName(String packageName, String baseUri) {
		List<Migration__c> migrationEntities = [ SELECT Checksum__c, Description__c, Installed_On__c, Package__c, Script__c, Type__c, Version__c FROM Migration__c WHERE Package__c = :packageName ];
		List<MigrationSummary> migrations = new List<MigrationSummary>();
		for (Migration__c migrationEntity : migrationEntities) {
			MigrationSummary migration = new MigrationSummary(migrationEntity.Version__c.intValue(), migrationEntity.Script__c, migrationEntity.Checksum__c.intValue());
			migration.url = baseUri + '/' + migrationEntity.Version__c;
			migrations.add(migration);
		}
		return migrations;
	}

	/**
	 * @description
	 * Runs the given migration against the package specified.
	 * If the migration already exists and the description and checksum of the saved migration match the migration being
	 * submitted, this method returns without doing anything.
	 * If the migration already exists and the description and/or checksum of the saved migration do not match the
	 * migration being submitted, a MigrationException is thrown and the migration is not run nor saved to the database.
	**/
	public void run(String packageName, Migration migration) {
		String data = migration.data;
		Migration__c migrationEntity = new Migration__c(
				Package__c = packageName,
				Version__c = migration.version,
				Checksum__c = migration.checksum,
				Description__c = migration.description,
				Installed_On__c = theClock.now(),
				Script__c = migration.script,
				Type__c = migration.type.name()
		);
		Database.SaveResult saveResult = Database.insert(migrationEntity, false);
		if (!saveResult.isSuccess()) {
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
				throw new MigrationException('Saving migration ' + migration.script + ' failed: ' + errorMessage);
			}

			// We have an existing migration. If it has the same script name and checksum, that's fine, ignore it.
			// If it has a different description or checksum, report it
			Datacloud.DuplicateResult duplicateResult = duplicateError.getDuplicateResult();
			Datacloud.MatchResult matchResult = duplicateResult.getMatchResults()[0];
			Datacloud.MatchRecord matchRecord = matchResult.getMatchRecords()[0];
			Id existingMigrationId = matchRecord.getRecord().Id;
			ExecutedMigration existingMigration =  getMigrationByPackageAndId(packageName, existingMigrationId);
			if (existingMigration.description != migration.description) {
				throw new MigrationException('Migration with version ' + migration.version + ' has changed: old description is "' + existingMigration.description + '", new description is "' + migration.description + '"');
			}
			if (existingMigration.checksum != migration.checksum) {
				throw new MigrationException('Migration with version ' + migration.version + ' has changed: old checksum is ' + existingMigration.checksum + ', new checksum is ' + migration.checksum);
			}

			// Fine, no error, but we're not going to run it since we already have
			return;
		}
		apexRunner.executeAnonymous(data);
	}

	/**
	 * @description
	 * Returns the details of a saved migration.
	**/
	public ExecutedMigration getMigration(String packageName, Integer version) {
		Migration__c migrationEntity = [ SELECT Checksum__c, Description__c, Installed_On__c, Package__c, Script__c, Type__c, Version__c FROM Migration__c WHERE Package__c = :packageName AND Version__c = :version ];
		ExecutedMigration migration = new ExecutedMigration();
		migration.description = migrationEntity.Description__c;
		migration.installedOn = migrationEntity.Installed_On__c;
		migration.script = migrationEntity.Script__c;
		migration.type = toType(migrationEntity.Type__c);
		migration.version = migrationEntity.Version__c.intValue();
		migration.checksum = migrationEntity.Checksum__c.intValue();
		return migration;
	}

	private ExecutedMigration getMigrationByPackageAndId(String packageName, Id id) {
		Migration__c migrationEntity = [ SELECT Checksum__c, Description__c, Installed_On__c, Package__c, Script__c, Type__c, Version__c FROM Migration__c WHERE Package__c = :packageName AND Id = :id ];
		ExecutedMigration migration = new ExecutedMigration();
		migration.description = migrationEntity.Description__c;
		migration.installedOn = migrationEntity.Installed_On__c;
		migration.script = migrationEntity.Script__c;
		migration.type = toType(migrationEntity.Type__c);
		migration.version = migrationEntity.Version__c.intValue();
		migration.checksum = migrationEntity.Checksum__c.intValue();
		return migration;
	}

	private Migration.Type toType(String s) {
		if (s == 'APEX') {
			return Migration.Type.APEX;
		}
		throw new IllegalArgumentException('Unknown migration type "' + s + '"');
	}
}
