def BC_FORMAT= 'GGGGGPPPPPPTTTVVVVVVVVVCLLLL'
def barcode = '09971-002497-002 5099301914 3380 '.replace(' ', '').replace('-', '')

println formatBarcode( BC_FORMAT, '-' )
println formatBarcode( barcode, '-' )

def printBarcodeComponents( barcode )
{
    def octets = parseBarcode( barcode )
    println "gameId: ${octets[0]}"
    println "packId: ${octets[1]}"
    println "ticketNr: ${octets[2]}"
    println "virn1: ${octets[3]}"
    println "virn2: ${octets[4]}"
    println "pin: ${octets[5]}"
}

def formatBarcode( barcode, sep )
{
    def octets = parseBarcode( barcode )
    def gameId   = octets[0]
    def packId   = octets[1]
    def ticketNr = octets[2]
    def virn1    = octets[3]
    def virn2    = octets[4]
    def pin      = octets[5]

    return "${gameId}${sep}${packId}${sep}${ticketNr}${sep}${virn1}${sep}${virn2}${sep}${pin}"
}

def parseBarcode( String barcode )
{
    def octets = []

    if ( barcode != null && barcode.length() == 28 )
    {

        String gameId = barcode.substring( 0, 5 );
        String packId = barcode.substring( 5, 11 );
        String ticketNr = barcode.substring( 11, 14 );
        String virn1 = barcode.substring( 14, 23 );
        String virn2 = barcode.substring( 23, 24 );
        String pin = barcode.substring( 24 );

        octets += gameId
        octets += packId
        octets += ticketNr
        octets += virn1
        octets += virn2
        octets += pin
    }
    else if ( barcode != null && barcode.length == 28 + 5 ) // 5 '-'
    {
        octets = barcode.split("-")
    }

    return octets
}