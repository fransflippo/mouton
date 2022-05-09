global class MigrationDefinition {

	// TODO Replace Type with type hierarchy (i.e. abstract superclass Migration and ApexMigration subclass)
    public enum Type {
		/**
         * A migration that is implemented by running an anonymous Apex script.
         */
        APEX
    }

	/**
     * The name of the migration script
     */
    public String scriptName;

	/**
     * The migration script itself: an anonymous Apex script
     */
    public String data;

	/**
	 * The migration version, determined from the script name
	 */
	public final Integer version {
		get {
			String[] parts = splitScriptName(scriptName);
			String versionString = parts[0];
			String migrationType = versionString.substring(0, 1);
			if (migrationType != 'V') {
				throw new IllegalArgumentException('Unknown prefix "' + migrationType + '" in script name: ' + scriptName);
			}

			versionString = versionString.substring(1);
			Integer version = Integer.valueOf(versionString);
			return version;
		}
	}

	/**
	 * The migration description, determined from the script name
	 */
	public final String description {
		get {
			String[] parts = splitScriptName(scriptName);
			String description = parts[1];
			return description.replace('_', ' ');
		}
	}

	/**
	 * The migration type, determined from the script name's file extension
	 */
	public final MigrationDefinition.Type type {
		get {
			String[] parts = splitScriptName(scriptName);
			String extension = parts[2];
			if ('apex'.equalsIgnoreCase(extension)) {
				return MigrationDefinition.Type.APEX;
			}
			throw new IllegalArgumentException('Unknown or unsupported script name extension ".' + extension + '": ' + scriptName);
		}
	}

	/**
	 * A CRC32 checksum of the migration data, used to determine whether the data has changed.
	 */
	public final Integer checksum {
		get {
			return CRC32.calculate(data);
		}
	}

	/**
	 * Splits a script name into its three parts: version, description, and extension.
	 * If the script name is invalid for some reason, throws an IllegalArgumentException.
	 * @param scriptName the script name to split
	 * @return the script name parts: <ol>
	 *     <li><code>[0]</code> contains the version part, e.g. V001
	 *     <li><code>[1]</code> contains the description
	 *     <li><code>[2]</code> contains the file extension, <em>not</em> including the leading dot (.)
	**/
	private static String[] splitScriptName(String scriptName) {
		String[] parts = scriptName.split('__', 2);
		if (parts.size() == 1) {
			throw new IllegalArgumentException('Invalid script name: ' + scriptName);
		}
		Integer p = parts[1].lastIndexOf('.');
		if (p == -1 || p == parts[1].length() - 1) {
			throw new IllegalArgumentException('Cannot determine type of migration with script name: ' + scriptName);
		}
		return new String[] {
				parts[0],
				parts[1].substring(0, p),
				parts[1].substring(p + 1)
		};
	}
}