<?php
$connection=mysqli_connect('us-cdbr-east-02.cleardb.com','b1166797b033d6','7e351580','heroku_7682f9ee17b688a');
if(!$connection){
    die('QUERRY FAILED'.mysqli_error($connection));
}
?>
