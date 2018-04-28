
function create_nonpublicPersonalInfo($player)
{
    $nonpublicPersonalInfo = New-Object PsObject -Property @{
        dateOfBirth = [string] (dateToEpochFormat $player.PlayerBirthdate)
    }

    return $nonpublicPersonalInfo
}

function create_caProfile($player)
{
    $caProfile  = New-Object PsObject -Property @{
        acceptsPromotionalEmail	 = [boolean]($player.PlayerPromotionalEmails -match "^1$")
        language               	 = $player.PlayerLanguage.ToUpper().Substring(0,2)
        registrationDate       	 = dateToEpochFormat $player.PlayerCreateDate
        acceptTermsAndConditions = [boolean]$True
        termsAndConditionsId     = dateToEpochFormat $player.PlayerCreateDate
        registrationLevel        = [int]1
        userName	             = $player.PlayerUsername
        jackpotCaptain	         = [boolean]($player.PlayerJackpotCaptain -match "^1$")
    }

    return $caProfile
}

function create_addresses($player)
{
    $addressMailObject = New-Object PsObject -Property @{
        street      = [string]$player.PlayerAddress
        address1	= [string]$player.PlayerAddress
        address2	= $player.PlayerAddress2
        city	    = $player.PlayerCity
        isoCountryCode = $player.PlayerCountry
        country	    = $player.PlayerCountry
        postalCode	= $player.PlayerZip
        state   	= $player.PlayerState
        verifyLevel	= $player.AddressVerifyLevel
    }

    $addresses = New-Object PsObject -Property @{
        MAILING = $addressMailObject
    }

    $addresses
}

function create_phones($player)
{
    $phonesHomeObject = New-Object PsObject -Property @{
        type = "HOME"
        number = $player.PlayerPhone
        provider = "Regular"
    }

    $phones = New-Object PsObject -Property @{
        HOME = $phonesHomeObject
    }

    return $phones
}

function create_emails($player)
{
    $PERSONALobj = New-Object PsObject -Property @{
        type     = "PERSONAL"
        address  = $player.PlayerEmail
        verified = [boolean]$false
        certaintyLevel = $player.EmailCertaintyLevel
    }

    $emails  = New-Object PsObject -Property @{
        PERSONAL = $PERSONALobj
    }

    return $emails
}

function convertToGender($v)
{
    $gender = "UNSPECIFIED"

    if ($v -match "M")
    {
        $gender = "MALE"
    }
    elseif ($v -match "F")
    {
        $gender = "FEMALE"
    }

    return $gender
}

function create_personalInfo ($player)
{
    $personalInfo = New-Object PsObject -Property @{
        firstName		= $player.PlayerFirstName
        middleName      = ""
        lastName		= $player.PlayerLastName
        gender		    = convertToGender $player.PlayerGender
        addresses       = create_addresses $player
        phones          = create_phones $player
        emails          = create_emails $player

        addressResultCode	 = $player.AddressResultCode
        dateOfBirth 	     = dateToEpochFormat $player.PlayerBirthdate
        dateOfBirthMatchCode = $player.DateOfBirthMatchCode
        errorCode		     = $player.ErrorCode
        userIdVerified		 = $player.UserIDVerified -replace '"', ''
        ssnresultCode		 = $player.SSNResultCode
        ofacvalidationResultCode = $player.OFACValidationResultCode -replace '"', ''
        telephoneVerificationResultCode	= $player.TelephoneVerificationResultCode
    }

    return $personalInfo
}

function create_registerUserDTO( $player, [string]$password )
{
    $DTO = New-Object PsObject -Property @{
        password = $password
        personalInfo = create_personalInfo $player
        nonpublicPersonalInfo = create_nonpublicPersonalInfo $player
        caProfile = create_caProfile $player
    }

    return $DTO
}
