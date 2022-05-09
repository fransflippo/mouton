public interface ApexRunner {

	/**
	 * Executes anonymous Apex.
	 * @return the Apex script's debug output
	 * @throws ApexRunnerException
	**/
	String executeAnonymous(String script);
}
