$filenames = ('components\admin\admin-frontend\src\main\webapp\admin.html')
$filenames += 'components\admin\admin-frontend\src\main\webapp\js\models\UserSessionModel.js'
$filenames += 'components\admin\admin-rest\admin-rest-web\src\main\resources\rest-context-admin-rest.xml'

foreach ($f in $filenames)
{
    #cp $env:TEST_SCRIPTS/pdadmin-hack/$f $env:CA
}
