global class MigrationSummary {

	/**
	 * The type of migration. Currently the only type supported is APEX.
	 */
	public final MigrationDefinition.Type type;
	public final Integer version;
	public final String script;
	public final Integer checksum;
	public String url;	// TODO Move to REST layer

    public MigrationSummary(Integer version, String script, Integer checksum) {
		this.type = MigrationDefinition.Type.APEX;
		this.version = version;
		this.script = script;
		this.checksum = checksum;
    }
}
