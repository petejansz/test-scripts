HOST=$1

curl -X POST \
  "https://$HOST/api/v2/players" \
  -H 'cache-control: no-cache' \
  -H 'content-type: application/json' \
  -H 'postman-token: bbb57aae-67aa-5298-b4d4-d7af2f27c5da' \
  -H 'x-channel-id: 2' \
  -H 'x-ex-system-id: 8' \
  -H 'x-site-id: 35' \
  -d '{
  "password" : "RegTest6100",
  "personalInfo" : {
    "firstName" : "TEST",
    "middleName" : "A",
    "lastName" : "LASTNAME",
    "gender" : "MALE",
    "addresses" : {
      "MAILING" : {
        "type" : "MAILING",
        "postalCode" : "90057",
        "city" : "SACRAMENTO",
        "isoCountryCode" : "US",
        "state" : "AZ",
        "country" : "US",
        "address1" : "123 Elm St",
        "address2" : "",
        "verifyLevel" : 7
      }
    },
    "phones" : {
      "HOME" : {
        "type" : "HOME",
        "number" : "2000000001",
        "provider" : "Regular"
      }
    },
    "emails" : {
      "PERSONAL" : {
        "type" : "PERSONAL",
        "address" : "test22@yopmail.com",
        "verified" : false,
        "certaintyLevel" : 200
      }
    },
    "citizenship" : "Resident",
    "suffix": "JR",
    "dateOfBirth" : 0,
    "errorCode" : "ERR",
    "addressResultCode" : "",
    "dateOfBirthMatchCode" : "",
    "userIdVerified" : "4",
    "ssnresultCode" : "",
    "ofacvalidationResultCode" : 1,
    "telephoneVerificationResultCode" : ""
  },
  "nonpublicPersonalInfo" : {
    "dateOfBirth" : 483017580000
  },
  "caProfile" : {
    "acceptedTermsAndConditionsDate": 1479920506894,
    "acceptsEmail": false,
    "acceptsPromotionalEmail": false,
    "acceptsRewards": false,
    "acceptTermsAndConditions": true,
    "language": "EN",
    "registrationDate": 1479920506900,
    "registrationLevel": 1,
    "termsAndConditionsId": "1479920506901",
    "userName": "test2@yopmail.com",
    "jackpotCaptain": false
  }
}'
