public class UTF8 {

	public static List<Integer> encode(String s) {
		List<Integer> bytes = new List<Integer>();
		for (Integer p = 0; p < s.length(); p++) {
			Integer c = s.codePointAt(p);
			if (c <= 127) {
				bytes.add(c & 127);
			} else if (c <= 2047) {
				bytes.add((c >> 6 & 31) | 192);
				bytes.add((c & 63) | 128);
			} else if (c <= 65535) {
			    bytes.add(c >> 12 & 15 | 224);
      			bytes.add(c >> 6  & 63 | 128);
      			bytes.add(c & 63 | 128);
			} else {
				bytes.add(c >> 18 & 7 | 240);
				bytes.add(c >> 12 & 63 | 128);
				bytes.add(c >> 6  & 63 | 128);
				bytes.add(c & 63 | 128);
			}
		}
		return bytes;
	}

}
