global class Migration {

    public enum Type {
        APEX
    }

    public String script;

    public String data;

	public final Integer version {
		get {
			String[] parts = splitScriptName(script);
			String versionString = parts[0];
			String migrationType = versionString.substring(0, 1);
			if (migrationType != 'V') {
				throw new IllegalArgumentException('Unknown prefix "' + migrationType + '" in script name: ' + script);
			}

			versionString = versionString.substring(1);
			Integer version = Integer.valueOf(versionString);
			return version;
		}
	}

	public final String description {
		get {
			String[] parts = splitScriptName(script);
			String description = parts[1];
			return description.replace('_', ' ');
		}
	}

	public final Migration.Type type {
		get {
			String[] parts = splitScriptName(script);
			String extension = parts[2];
			if ('apex'.equalsIgnoreCase(extension)) {
				return Migration.Type.APEX;
			}
			throw new IllegalArgumentException('Unknown or unsupported script name extension ".' + extension + '": ' + script);
		}
	}

	public final Integer checksum {
		get {
			return CRC32.calculate(data);
		}
	}

	/**
	 * Splits a script name into its three parts: version, description, and extension.
	 * If the script name is invalid for some reason, throws an IllegalArgumentException.
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