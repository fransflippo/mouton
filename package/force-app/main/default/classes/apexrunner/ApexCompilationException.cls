public class ApexCompilationException extends ApexRunnerException {
    public String compileProblem;
    public Integer line;
    public Integer column;

    public ApexCompilationException(String compileProblem, Integer line, Integer column) {
        this.compileProblem = compileProblem;
        this.line = line;
        this.column = column;
    }
}
