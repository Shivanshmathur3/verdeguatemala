<?php
$connection=mysqli_connect('us-cdbr-east-02.cleardb.com','b100fd91b543b3','074cb359','heroku_a79d6bee30a0d13');
if(!$connection){
    die('QUERRY FAILED'.mysqli_error($connection));
}
?>

