<?php
include "functions.php";
?>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">

    <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/4.0.0/css/bootstrap.min.css" integrity="sha384-Gn5384xqQ1aoWXA+058RXPxPg6fy4IWvTNh0E263XmFcJlSAwiGgFAW/dAiS6JXm" crossorigin="anonymous">

    <script src="https://code.jquery.com/jquery-3.2.1.slim.min.js" integrity="sha384-KJ3o2DKtIkvYIK3UENzmM7KCkRr/rE9/Qpg6aAZGJwFDMVNA/GpGFF93hXpG5KkN" crossorigin="anonymous"></script>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/popper.js/1.12.9/umd/popper.min.js" integrity="sha384-ApNbgh9B+Y1QKtv3Rn7W3mgPxhU9K/ScQsAP7hUibX39j7fakFPskvXusvfa0b4Q" crossorigin="anonymous"></script>
    <script src="https://maxcdn.bootstrapcdn.com/bootstrap/4.0.0/js/bootstrap.min.js" integrity="sha384-JZR6Spejh4U02d8jOt6vLEHfe/JQGiRRSQQxSfFWpi1MquVdAyjUar5+76PVCmYl" crossorigin="anonymous"></script>
    <title>db_admin</title>
</head>
<body>
    <div class="container">
      <?php 
      $query="SELECT * FROM form";
      $send_query=mysqli_query($connection,$query);
      
      if(!$send_query)
      {
          die("QUERY FAILED ".mysqli_error($connection));
      }
       ?>

       <table class="table">
            <tbody>

                <?php
                $count=0;
                    while($row=mysqli_fetch_assoc($send_query)){
                        $requirements=$row['requirements'];
                        $name=$row['name'];
                        $companyName=$row['companyName'];
                        $address=$row['address'];
                        $phoneNumber=$row['phoneNumber'];
                        $faxNumber=$row['faxNumber'];
                        $emailAddress=$row['emailAddress'];
                        //echo $count;
                            if($count%3==0) 
                            {
                             echo "<tr>";
                            }
                        ?>
                        
                            <!-- <div class="col"> -->
                                <td>
                                    <div class="card" style="width: 18rem;">
                                        <div class="card-body">
                                            <h5 class="card-title"><?php echo $name; ?></h5>
                                        </div>
                                        <ul class="list-group list-group-flush">
                                            <li class="list-group-item">Address- <?php echo $address; ?></li>
                                            <li class="list-group-item">Company Name- <?php echo $companyName; ?></li>
                                            <li class="list-group-item">Fax Number- <?php echo $faxNumber ?></li>
                                        </ul>
                                        <div class="card-body">
                                            <a href="#" class="card-link">Phone Number- <?php echo $phoneNumber; ?></a></br>
                                            <a href="#" class="card-link">E-mail Address- <?php echo $emailAddress; ?></a>
                                        </div>
                                    </div>
                                </td>
                            <!-- </div> -->

                            <?php 
                            $count++;
                            if($count%3==0)
                            if(!$count==0)
                            {
                                {
                                    echo "</tr>";
                                }
                            }
                            
                        }
                        ?>
            </tbody>
        </table>    
    </div>
</body>
</html>

