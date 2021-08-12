public class CRC32 {

	public static Integer calculate(String s) {
		// Convert string to list of bytes (represented as Integers as Apex doesn't have a Byte type)
		List<Integer> bytes = UTF8.encode(s);

		// Iterates each byte of the input stream
		return calculate(bytes);
	}

	private static Integer calculate(List<Integer> bytes) {
		Integer crc = -1; // The Initial CRC32 value 0xffffffff
		Integer polynomial = -306674912;   // The CRC32 polynomial 0xedb88320

		for (Integer b : bytes) {
			Integer remainder = (crc & 255) ^ b; // XOR LSB of CRC with current byte
			// 8-bit lsb shift with XOR polynomial reminder when odd
			for (Integer i = 0; i < 8; i++) {
				Integer t = remainder >>> 1;
				if ((remainder & 1) == 1) {
					remainder = t ^ polynomial;
				 } else {
					 remainder = t;
				 }
			}
			crc = (crc >>> 8) ^ remainder; // XOR MSB of CRC with Reminder
		}
		crc ^= -1;	// XOR mask 32 bits
		return crc;
	}
}
