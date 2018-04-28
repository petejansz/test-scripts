// Barcode checksum algorithm.

String barcode2 = "0900-000008-001-900-26-00701";
String[] octets = barcode2.split('-')
assert octets.length == 6
String book = octets[1]; //"000008";
String game = octets[3]; //"900";

String tkt = octets[2]; //"001";
String barcodeChecksum = octets[4] // "26"
String virn = game + octets[5]; //"90000701";
String frmt = "0";
char CHAR_ZERO = '0';

int temp100 = ((Character.getNumericValue(book.charAt(1)) + Character.getNumericValue(virn.charAt(0))
        + Character.getNumericValue(tkt.charAt(0)) + Character.getNumericValue(virn.charAt(3))
        + Character.getNumericValue(virn.charAt(4))) * 13) +
        ((Character.getNumericValue(game.charAt(0)) + Character.getNumericValue(book.charAt(4))
                + Character.getNumericValue(game.charAt(2)) + Character.getNumericValue(virn.charAt(2))
                + Character.getNumericValue(virn.charAt(5))) * 27) +
        ((Character.getNumericValue(game.charAt(1)) + Character.getNumericValue(book.charAt(2))
                + Character.getNumericValue(tkt.charAt(2)) + Character.getNumericValue(CHAR_ZERO)
                + Character.getNumericValue(virn.charAt(1)) + Character.getNumericValue(virn.charAt(6))) * 6) +
        ((Character.getNumericValue(book.charAt(0)) + Character.getNumericValue(book.charAt(3))
                + Character.getNumericValue(tkt.charAt(1)) + Character.getNumericValue(book.charAt(5))
                + Character.getNumericValue(virn.charAt(7))) * 19);

def checksum = temp100 % 100;
assert checksum == Integer.parseInt(barcodeChecksum)
println checksum

