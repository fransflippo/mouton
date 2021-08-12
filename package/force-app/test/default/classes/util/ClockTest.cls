@IsTest
public class ClockTest {

	@IsTest
	public static void testSystemClock() {
		// Given
		Clock systemClock = Clock.system();
		Datetime now = Datetime.now();

		// When
		Datetime clockNow = systemClock.now();

		// Then
		System.assert(Math.abs(now.getTime() - clockNow.getTime()) < 50);
	}

}