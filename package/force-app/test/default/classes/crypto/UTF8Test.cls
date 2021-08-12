@IsTest
private class UTF8Test {

    @IsTest
    static void testEncode_emptyString() {
        // Given
        String s = '';

        // When
        List<Integer> bytes = UTF8.encode(s);

        // Then
        System.assertEquals(new List<Integer> { }, bytes);
    }

    @IsTest
    static void testEncode_AsciiString() {
        // Given
        String s = 'The quick brown fox jumps over the lazy dog';

        // When
        List<Integer> bytes = UTF8.encode(s);

        // Then
        System.assertEquals(new List<Integer> { 84, 104, 101, 32, 113, 117, 105, 99, 107, 32, 98, 114, 111, 119, 110, 32, 102, 111, 120, 32, 106, 117, 109, 112, 115, 32, 111, 118, 101, 114, 32, 116, 104, 101, 32, 108, 97, 122, 121, 32, 100, 111, 103 }, bytes);
    }

    @IsTest
    static void testEncode_Latin1String() {
        // Given
        String s = 'Enchanté, François! Allons-nous a l\'hôtel.';

        // When
        List<Integer> bytes = UTF8.encode(s);

        // Then
        System.assertEquals(new List<Integer> { 69, 110, 99, 104, 97, 110, 116, 195, 169, 44, 32, 70, 114, 97, 110, 195, 167, 111, 105, 115, 33, 32, 65, 108, 108, 111, 110, 115, 45, 110, 111, 117, 115, 32, 97, 32, 108, 39, 104, 195, 180, 116, 101, 108, 46 }, bytes);
    }

    @IsTest
    static void testEncode_NonLatin1String() {
        // Given
		String s = 'Daß ist überhaupt nicht möglich mit nur €1!';

        // When
        List<Integer> bytes = UTF8.encode(s);

        // Then
        System.assertEquals(new List<Integer> { 68, 97, 195, 159, 32, 105, 115, 116, 32, 195, 188, 98, 101, 114, 104, 97, 117, 112, 116, 32, 110, 105, 99, 104, 116, 32, 109, 195, 182, 103, 108, 105, 99, 104, 32, 109, 105, 116, 32, 110, 117, 114, 32, 226, 130, 172, 49, 33 }, bytes);
    }

    @IsTest
    static void testEncode_Kanji() {
        // Given
	    String s = '彼は食べ過ぎないようにしている。';

        // When
        List<Integer> bytes = UTF8.encode(s);

        // Then
        System.assertEquals(new List<Integer> { 229, 189, 188, 227, 129, 175, 233, 163, 159, 227, 129, 185, 233, 129, 142, 227, 129, 142, 227, 129, 170, 227, 129, 132, 227, 130, 136, 227, 129, 134, 227, 129, 171, 227, 129, 151, 227, 129, 166, 227, 129, 132, 227, 130, 139, 227, 128, 130 }, bytes);
    }

    @IsTest
    static void testEncode_Emoji() {
        // Given
	    String s = 'LOL 😂🤣😂';

        // When
        List<Integer> bytes = UTF8.encode(s);

        // Then
        System.assertEquals(new List<Integer> { 76, 79, 76, 32, 240, 159, 152, 130, 240, 159, 164, 163, 240, 159, 152, 130 }, bytes);
    }
}