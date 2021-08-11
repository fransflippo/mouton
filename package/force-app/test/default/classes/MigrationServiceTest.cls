@IsTest
private class MigrationServiceTest {

	// TODO Pull in mocking framework to mock away ApexRunner

	private static final String TEST_MIGRATION_SCRIPT =
			'List<Account> accounts = [ SELECT Id, Name FROM Account ];\n' +
			'for (Account account : accounts) {\n' +
			'    account.Name = account.Name + \' updated\';\n' +
			'}\n' +
			'update accounts;\n';

	private static final Datetime NOW = Datetime.newInstanceGmt(2021, 8, 11, 19, 5, 26);

	private static ApexRunner apexRunner;
	private static MigrationService migrationService = new MigrationService();
	static {
		apexRunner = (ApexRunner) Test.createStub(ApexRunner.class, new StubProviderImpl());
		migrationService.apexRunner = apexRunner;

		migrationService.theClock = Clock.fixed(NOW);
	}

	private static void insertMigrations() {
		insert new List<Migration__c> {
			new Migration__c(
				Checksum__c = 0,
				Description__c = 'Test migration 1',
				Installed_On__c = Datetime.newInstanceGmt(2020, 1, 2, 14, 32, 17),
				Package__c = 'myPackage1',
				Script__c = 'V001__Test_migration_1.apex',
				Type__c = 'APEX',
				Version__c = 1
			),
			new Migration__c(
				Checksum__c = 0,
				Description__c = 'Test migration 2',
				Installed_On__c = Datetime.newInstanceGmt(2020, 2, 2, 14, 32, 17),
				Package__c = 'myPackage3',
				Script__c = 'V002__Test_migration_2.apex',
				Type__c = 'APEX',
				Version__c = 2
			),
			new Migration__c(
				Checksum__c = 50,
				Description__c = 'Test migration 3',
				Installed_On__c = Datetime.newInstanceGmt(2020, 3, 2, 14, 32, 17),
				Package__c = 'myPackage2',
				Script__c = 'V003__Test_migration_3.apex',
				Type__c = 'APEX',
				Version__c = 3
			),
			new Migration__c(
				Checksum__c = 0,
				Description__c = 'Test migration 4',
				Installed_On__c = Datetime.newInstanceGmt(2020, 4, 2, 14, 32, 17),
				Package__c = 'myPackage1',
				Script__c = 'V004__Test_migration_4.apex',
				Type__c = 'APEX',
				Version__c = 4
			),
			new Migration__c(
				Checksum__c = 100,
				Description__c = 'Test migration 5',
				Installed_On__c = Datetime.newInstanceGmt(2020, 5, 2, 14, 32, 17),
				Package__c = 'myPackage2',
				Script__c = 'V005__Test_migration_5.apex',
				Type__c = 'APEX',
				Version__c = 5
			)
		};
	}

    @IsTest
	public static void testGetPackages_noPackages() {
		// Given

		// When
		List<String> packages = migrationService.getPackages();

		// Then
		System.assertEquals(0, packages.size());
	}

    @IsTest
	public static void testGetPackages() {
		// Given
		insertMigrations();

		// When
		List<String> packages = migrationService.getPackages();

		// Then
		System.assertEquals(3, packages.size());
		System.assertEquals('myPackage1', packages[0]);
		System.assertEquals('myPackage2', packages[1]);
		System.assertEquals('myPackage3', packages[2]);
	}

    @IsTest
	public static void testFindByPackageName() {
		// Given
		insertMigrations();

		// When
		List<MigrationSummary> migrations = migrationService.findByPackageName('myPackage2', 'http://localhost/migrations/myPackage2');

		// Then
		System.assertEquals(2, migrations.size());
		System.assertEquals(50, migrations[0].checksum);
		System.assertEquals(3, migrations[0].version);
		System.assertEquals('V003__Test_migration_3.apex', migrations[0].script);
		System.assertEquals('http://localhost/migrations/myPackage2/3', migrations[0].url);
		System.assertEquals(100, migrations[1].checksum);
		System.assertEquals(5, migrations[1].version);
		System.assertEquals('V005__Test_migration_5.apex', migrations[1].script);
		System.assertEquals('http://localhost/migrations/myPackage2/5', migrations[1].url);
	}

    @IsTest
	public static void testRun_newMigration() {
		// Given
		Migration migration = new Migration();
		migration.script = 'V002__Test_migration.apex';
		migration.data = TEST_MIGRATION_SCRIPT;

		// When
		migrationService.run('myPackage', migration);

		// Then
		List<Migration__c> savedMigrations = [ SELECT Checksum__c, Description__c, Installed_On__c, Package__c, Script__c, Type__c, Version__c FROM Migration__c ];
		System.assertEquals(1, savedMigrations.size());
		Migration__c savedMigration = savedMigrations[0];
		System.assertEquals(-1976816763, savedMigration.Checksum__c);
		System.assertEquals('Test migration', savedMigration.Description__c);
		System.assertEquals(NOW, savedMigration.Installed_On__c);
		System.assertEquals('myPackage', savedMigration.Package__c);
		System.assertEquals('V002__Test_migration.apex', savedMigration.Script__c);
		System.assertEquals('APEX', savedMigration.Type__c);
		System.assertEquals(2, savedMigration.Version__c);

		// Assert that the migration was run
		System.assertEquals(1, methodInvocations.size());
		MethodInvocation invocation = methodInvocations[0];
		System.assertEquals(apexRunner, invocation.stubbedObject);
		System.assertEquals('executeAnonymous', invocation.stubbedMethodName);
		System.assertEquals(1, invocation.listOfArgs.size());
		System.assertEquals(TEST_MIGRATION_SCRIPT, invocation.listOfArgs[0]);

	}

    @IsTest
	public static void testRun_error() {
		// Given
		Migration migration = new Migration();
		migration.script = 'V002__Test_migration.apex';
		migration.data = TEST_MIGRATION_SCRIPT;

		// When
		try {
			migrationService.run('', migration);
			System.assert(false, 'Expected MigrationException');
		} catch (MigrationException e) {
			System.assertEquals('Saving migration V002__Test_migration.apex failed: Required fields are missing: [m7n__Package__c]', e.getMessage());
		}

		// Then
		List<Migration__c> savedMigrations = [ SELECT Checksum__c, Description__c, Installed_On__c, Package__c, Script__c, Type__c, Version__c FROM Migration__c ];
		System.assertEquals(0, savedMigrations.size());

		// Assert that the migration was run
		System.assertEquals(0, methodInvocations.size());
	}

    @IsTest
	public static void testRun_existingMigration_checksumAndDescriptionMatch() {
		// Given
		Migration__c existingMigration = new Migration__c(
				Checksum__c = -1976816763,
				Description__c = 'Test migration',
				Installed_On__c = Datetime.newInstanceGmt(2021, 8, 11, 12, 34, 56),
				Package__c = 'myPackage',
				Script__c = 'V002__Test_migration.apex',
				Type__c = 'APEX',
				Version__c = 2
		);
		insert existingMigration;

		Migration migration = new Migration();
		migration.script = 'V002__Test_migration.apex';
		migration.data = TEST_MIGRATION_SCRIPT;

		// When
		migrationService.run('myPackage', migration);

		// Then
		List<Migration__c> savedMigrations = [ SELECT Checksum__c, Description__c, Installed_On__c, Package__c, Script__c, Type__c, Version__c FROM Migration__c ];
		System.assertEquals(1, savedMigrations.size());
		// Assert existing migration not changed
		Migration__c savedMigration = savedMigrations[0];
		System.assertEquals(-1976816763, savedMigration.Checksum__c);
		System.assertEquals('Test migration', savedMigration.Description__c);
		System.assertEquals(Datetime.newInstanceGmt(2021, 8, 11, 12, 34, 56), savedMigration.Installed_On__c);
		System.assertEquals('myPackage', savedMigration.Package__c);
		System.assertEquals('V002__Test_migration.apex', savedMigration.Script__c);
		System.assertEquals('APEX', savedMigration.Type__c);
		System.assertEquals(2, savedMigration.Version__c);

		// Assert that the migration did not run
		System.assertEquals(0, methodInvocations.size());
	}

    @IsTest
	public static void testRun_existingMigration_checksumDoesNotMatch() {
		// Given
		Migration__c existingMigration = new Migration__c(
				Checksum__c = -1976816762,
				Description__c = 'Test migration',
				Installed_On__c = Datetime.newInstanceGmt(2021, 8, 11, 12, 34, 56),
				Package__c = 'myPackage',
				Script__c = 'V002__Test_migration.apex',
				Type__c = 'APEX',
				Version__c = 2
		);
		insert existingMigration;

		Migration migration = new Migration();
		migration.script = 'V002__Test_migration.apex';
		migration.data = TEST_MIGRATION_SCRIPT;

		// When
		try {
			migrationService.run('myPackage', migration);
			System.assert(false, 'Expected MigrationException');
		} catch (MigrationException e) {
			// Then
			System.assertEquals('Migration with version 2 has changed: old checksum is -1976816762, new checksum is -1976816763', e.getMessage());
		}
		List<Migration__c> savedMigrations = [ SELECT Checksum__c, Description__c, Installed_On__c, Package__c, Script__c, Type__c, Version__c FROM Migration__c ];
		System.assertEquals(1, savedMigrations.size());
		// Assert existing migration not changed
		Migration__c savedMigration = savedMigrations[0];
		System.assertEquals(-1976816762, savedMigration.Checksum__c);
		System.assertEquals('Test migration', savedMigration.Description__c);
		System.assertEquals(Datetime.newInstanceGmt(2021, 8, 11, 12, 34, 56), savedMigration.Installed_On__c);
		System.assertEquals('myPackage', savedMigration.Package__c);
		System.assertEquals('V002__Test_migration.apex', savedMigration.Script__c);
		System.assertEquals('APEX', savedMigration.Type__c);
		System.assertEquals(2, savedMigration.Version__c);

		// Assert that the migration did not run
		System.assertEquals(0, methodInvocations.size());
	}

    @IsTest
	public static void testRun_existingMigration_descriptionDoesNotMatch() {
		// Given
		Migration__c existingMigration = new Migration__c(
				Checksum__c = -1976816763,
				Description__c = 'Test_migration',
				Installed_On__c = Datetime.newInstanceGmt(2021, 8, 11, 12, 34, 56),
				Package__c = 'myPackage',
				Script__c = 'V002__Test_migration.apex',
				Type__c = 'APEX',
				Version__c = 2
		);
		insert existingMigration;

		Migration migration = new Migration();
		migration.script = 'V002__Test_migration.apex';
		migration.data = TEST_MIGRATION_SCRIPT;

		// When
		try {
			migrationService.run('myPackage', migration);
			System.assert(false, 'Expected MigrationException');
		} catch (MigrationException e) {
			// Then
			System.assertEquals('Migration with version 2 has changed: old description is "Test_migration", new description is "Test migration"', e.getMessage());
		}
		List<Migration__c> savedMigrations = [ SELECT Checksum__c, Description__c, Installed_On__c, Package__c, Script__c, Type__c, Version__c FROM Migration__c ];
		System.assertEquals(1, savedMigrations.size());
		// Assert existing migration not changed
		Migration__c savedMigration = savedMigrations[0];
		System.assertEquals(-1976816763, savedMigration.Checksum__c);
		System.assertEquals('Test_migration', savedMigration.Description__c);
		System.assertEquals(Datetime.newInstanceGmt(2021, 8, 11, 12, 34, 56), savedMigration.Installed_On__c);
		System.assertEquals('myPackage', savedMigration.Package__c);
		System.assertEquals('V002__Test_migration.apex', savedMigration.Script__c);
		System.assertEquals('APEX', savedMigration.Type__c);
		System.assertEquals(2, savedMigration.Version__c);

		// Assert that the migration did not run
		System.assertEquals(0, methodInvocations.size());

	}

    @IsTest
	public static void testRun_unsupportedMigrationType() {
		// Given
		Migration migration = new Migration();
		migration.script = 'V002__Test_migration.sql';
		migration.data = TEST_MIGRATION_SCRIPT;

		// When
		try {
			migrationService.run('myPackage', migration);
			System.assert(false, 'Expected MigrationException');
		} catch (IllegalArgumentException e) {
			// Then
			System.assertEquals('Unknown or unsupported script name extension ".sql": V002__Test_migration.sql', e.getMessage());
		}
		List<Migration__c> savedMigrations = [ SELECT Checksum__c, Description__c, Installed_On__c, Package__c, Script__c, Type__c, Version__c FROM Migration__c ];
		System.assertEquals(0, savedMigrations.size());
		// Assert that the migration did not run
		System.assertEquals(0, methodInvocations.size());
	}

    @IsTest
	public static void testRun_newMigration_invalidScriptName_missingVersion() {
		// Given
		Migration migration = new Migration();
		migration.script = 'Test_migration.apex';
		migration.data = TEST_MIGRATION_SCRIPT;

		// When
		try {
			migrationService.run('myPackage', migration);
			System.assert(false, 'Expected IllegalArgumentException');
		} catch (IllegalArgumentException e) {
		}

		// Then
		List<Migration__c> savedMigrations = [ SELECT Checksum__c, Description__c, Installed_On__c, Package__c, Script__c, Type__c, Version__c FROM Migration__c ];
		System.assertEquals(0, savedMigrations.size());
	}

    @IsTest
	public static void testRun_newMigration_invalidScriptName_invalidMigrationType() {
		// Given
		Migration migration = new Migration();
		migration.script = 'W001__Test_migration.apex';
		migration.data = TEST_MIGRATION_SCRIPT;

		// When
		try {
			migrationService.run('myPackage', migration);
			System.assert(false, 'Expected IllegalArgumentException');
		} catch (IllegalArgumentException e) {
		}

		// Then
		List<Migration__c> savedMigrations = [ SELECT Checksum__c, Description__c, Installed_On__c, Package__c, Script__c, Type__c, Version__c FROM Migration__c ];
		System.assertEquals(0, savedMigrations.size());
	}

    @IsTest
	public static void testRun_newMigration_invalidScriptName_noFileExtension() {
		// Given
		Migration migration = new Migration();
		migration.script = 'V001__Test_migration';
		migration.data = TEST_MIGRATION_SCRIPT;

		// When
		try {
			migrationService.run('myPackage', migration);
			System.assert(false, 'Expected IllegalArgumentException');
		} catch (IllegalArgumentException e) {
		}

		// Then
		List<Migration__c> savedMigrations = [ SELECT Checksum__c, Description__c, Installed_On__c, Package__c, Script__c, Type__c, Version__c FROM Migration__c ];
		System.assertEquals(0, savedMigrations.size());
	}

	@IsTest
	public static void testGetMigration() {
		// Given
		insertMigrations();

		// When
		ExecutedMigration executedMigration = migrationService.getMigration('myPackage2', 5);

		// Then
		System.assertEquals('Test migration 5', executedMigration.description);
		System.assertEquals(Datetime.newInstanceGmt(2020, 5, 2, 14, 32, 17), executedMigration.installedOn);
		System.assertEquals('V005__Test_migration_5.apex', executedMigration.script);
		System.assertEquals(Migration.Type.APEX, executedMigration.type);
		System.assertEquals(5, executedMigration.version);
		System.assertEquals(100, executedMigration.checksum);
	}

	// Mock handling

	private class MethodInvocation {
		public Object stubbedObject;
		public String stubbedMethodName;
		public Type returnType;
		public List<Type> listOfParamTypes;
		public List<String> listOfParamNames;
		public List<Object> listOfArgs;
	}

	private static List<MethodInvocation> methodInvocations = new List<MethodInvocation>();

	public class StubProviderImpl implements System.StubProvider {

		public Object handleMethodCall(Object stubbedObject, String stubbedMethodName, Type returnType, List<Type> listOfParamTypes, List<String> listOfParamNames, List<Object> listOfArgs) {
			MethodInvocation methodInvocation = new MethodInvocation();
			methodInvocation.stubbedObject = stubbedObject;
			methodInvocation.stubbedMethodName = stubbedMethodName;
			methodInvocation.returnType = returnType;
			methodInvocation.listOfParamTypes = listOfParamTypes;
			methodInvocation.listOfParamNames = listOfParamNames;
			methodInvocation.listOfArgs = listOfArgs;
			methodInvocations.add(methodInvocation);
			return null;
		}
	}
}