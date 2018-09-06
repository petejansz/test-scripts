curl -X POST \
  https://mobile-cat.calottery.com/api/v2/players \
  -H 'cache-control: no-cache' \
  -H 'content-type: application/json' \
  -H 'x-channel-id: 3' \
  -H 'x-esa-api-key: DBRDtq3tUERv79ehrheOUiGIrnqxTole' \
  -H 'x-ex-system-id: 8' \
  -H 'x-site-id: 35' \
  -d '{
  "password" : "Password1",
  "personalInfo" : {
    "firstName" : "TASTE",
    "middleName" : "Z",
    "lastName" : "LASTNAME",
    "gender" : "MALE",
    "addresses" : {
      "MAILING" : {
        "type" : "MAILING",
        "postalCode" : "90057",
        "city" : "LOS ANGELES",
        "isoCountryCode" : "US",
        "state" : "CA",
        "country" : "US",
        "address1" : "123 main st",
        "address2" : "",
        "verifyLevel" : 7
      }
    },
    "phones" : {
      "HOME" : {
        "type" : "HOME",
        "number" : "1000000000",
        "provider" : "Regular"
      }
    },
    "emails" : {
      "PERSONAL" : {
        "type" : "PERSONAL",
        "address" : "test23@yopmail.com",
        "verified" : false,
        "certaintyLevel" : 200
      }
    },
    "citizenship" : "Resident",
    "suffix": "",
    "dateOfBirth" : 0,
    "errorCode" : "ERR",
    "addressResultCode" : "",
    "dateOfBirthMatchCode" : "",
    "userIdVerified" : null,
    "ssnresultCode" : "",
    "ofacvalidationResultCode" : 1,
    "telephoneVerificationResultCode" : ""
  },
  "nonpublicPersonalInfo" : {
    "dateOfBirth" : 483017580000
  },
  "caProfile" : {
    "acceptedTermsAndConditionsDate": 1479920506894,
    "acceptsEmail": true,
    "acceptsPromotionalEmail": true,
    "acceptsRewards": true,
    "acceptTermsAndConditions": true,
    "language": "EN",
    "registrationDate": 1479920506900,
    "registrationLevel": 1,
    "termsAndConditionsId": "1479920506901",
    "userName": "test23@yopmail.com",
    "jackpotCaptain": false
  }
}'