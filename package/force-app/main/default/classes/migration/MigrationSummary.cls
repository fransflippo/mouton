global class MigrationSummary {

	public final Integer version;
	public final String script;
	public final Integer checksum;
	public String url;

    public MigrationSummary(Integer version, String script, Integer checksum) {
		this.version = version;
		this.script = script;
		this.checksum = checksum;
    }
}
