<?php
$connection=mysqli_connect('localhost','root','','verdeguatemala');
if(!$connection){
    die('QUERRY FAILED'.mysqli_error($connection));
}
?>