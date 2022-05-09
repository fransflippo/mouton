public class ApexExecutionException extends ApexRunnerException {
    public String exceptionMessage;
    public String exceptionStackTrace;
    public Integer line;
    public Integer column;
    public String debugLog;

    public ApexExecutionException(String exceptionMessage, String exceptionStackTrace, Integer line, Integer column, String debugLog) {
        this.exceptionMessage = exceptionMessage;
        this.exceptionStackTrace = exceptionStackTrace;
        this.line = line;
        this.column = column;
        this.debugLog = debugLog;
    }

}
