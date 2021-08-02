@IsTest
private class CRC32Test {

    @IsTest
    static void testCrc32_emptyString() {
        // Given
        String s = '';

        // When
        Integer checksum = CRC32.calculate(s);

        // Then
        System.assertEquals(0, checksum);
    }

    @IsTest
    static void testCrc32_AsciiString() {
        // Given
        String s = 'The quick brown fox jumps over the lazy dog';

        // When
        Integer checksum = CRC32.calculate(s);

        // Then
        System.assertEquals(1095738169, checksum);
    }

    @IsTest
    static void testCrc32_Latin1String() {
        // Given
        String s = 'Enchanté, François! Allons-nous a l\'hôtel.';

        // When
        Integer checksum = CRC32.calculate(s);

        // Then
        System.assertEquals(631701539, checksum);
    }

    @IsTest
    static void testCrc32_NonLatin1String() {
        // Given
		String s = 'Daß ist überhaupt nicht möglich mit nur €1!';

        // When
        Integer checksum = CRC32.calculate(s);

        // Then
        System.assertEquals(-361295279, checksum);
    }

    @IsTest
    static void testCrc32_Kanji() {
        // Given
	    String s = '彼は食べ過ぎないようにしている。';

        // When
        Integer checksum = CRC32.calculate(s);

        // Then
        System.assertEquals(-1307603566, checksum);
    }

}