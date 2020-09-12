<?php
include "functions.php";
if(isset($_POST['submit'])){
    $requirements=mysqli_real_escape_string($connection,$_POST['srequire']);
    $name=mysqli_real_escape_string($connection,$_POST['sname']);
    $companyName=mysqli_real_escape_string($connection,$_POST['scompany']);
    $address=mysqli_real_escape_string($connection,$_POST['saddress']);
    $phoneNumber=mysqli_real_escape_string($connection,$_POST['sphone']);
    $faxNumber=mysqli_real_escape_string($connection,$_POST['sfax']);
    $emailAddress=mysqli_real_escape_string($connection,$_POST['smail']);

    $query="INSERT INTO form (requirements, name, companyName, address, phoneNumber, faxNumber, emailAddress) ";
    $query.="VALUES('{$requirements}','{$name}','{$companyName}','{$address}', {$phoneNumber}, {$faxNumber},'{$emailAddress}')";
    global $connection;
    $send_query=mysqli_query($connection,$query);
    if(!$send_query){
        die("QUERY FAILED".mysqli_error($connection));
    }
    else{
        header("LOCATION: db_admin.php");
    }
}
?>