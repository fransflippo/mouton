public abstract class Clock {

	public abstract Datetime now();

	public static Clock system() {
		return new SystemClock();
	}

	public static Clock fixed(Datetime now) {
		return new FixedClock(now);
	}

	private class SystemClock extends Clock {
		public override Datetime now() {
			return Datetime.now();
		}
	}

	private class FixedClock extends Clock {
		private Datetime now;

		public FixedClock(Datetime now) {
			this.now = now;
		}

		public override Datetime now() {
			return now;
		}
	}

}