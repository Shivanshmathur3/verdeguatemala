#!/usr/bin/perl
$mail_prog = '/usr/sbin/sendmail' ;
# This script was generated automatically by Visual Form Mail: http://www.oneseek.com

&GetFormInput;


@valid_ref = ('http://www.verdeguatemala.net','https://www.verdeguatemala.net','http://verdeguatemala.net') ;
foreach $ref (@valid_ref) {
if ($ENV{'HTTP_REFERER'} =~ m/$ref/i) {$is_valid = 1 ; last ;}
}
if (! $is_valid) {
print "Content-type: text/html\n\nERROR - Invalid Referrer\n" ;
exit 0 ;
}

$srequire = $field{'srequire'} ;	 
$sname = $field{'sname'} ;	 
$scompany = $field{'scompany'} ;	 
$saddress = $field{'saddress'} ;	 
$sphone = $field{'sphone'} ;	 
$sfax = $field{'sfax'} ;	 
$smail = $field{'smail'} ;	 

$message = "" ;
$found_err = "" ;

$errmsg = "<p>Please Fill Your Requirements.</p>\n" ;

if ($srequire eq "") {
	$message = $message.$errmsg ;
	$found_err = 1 ; }


$errmsg = "<p>Please Write Your name</p>\n" ;

if ($sname eq "") {
	$message = $message.$errmsg ;
	$found_err = 1 ; }


$errmsg = "<p>Please write your Company Name</p>\n" ;

if ($scompany eq "") {
	$message = $message.$errmsg ;
	$found_err = 1 ; }


$errmsg = "<p>Please Write Your Address</p>\n" ;

if ($saddress eq "") {
	$message = $message.$errmsg ;
	$found_err = 1 ; }


$errmsg = "<p>Please Let Us know Your Phone Number</p>\n" ;

if ($sphone eq "") {
	$message = $message.$errmsg ;
	$found_err = 1 ; }


$errmsg = "<p>Please enter a valid email address</p>\n" ;

if (($smail =~ /(@.*@)|(\.\.)|(@\.)|(\.@)|(^\.)/) || ($smail !~ /^.+\@(\[?)[a-zA-Z0-9\-\.]+\.([a-zA-Z0-9]+)(\]?)$/)) {
	$message = $message.$errmsg ;
	$found_err = 1 ; }

if ($found_err) {
	&PrintError; }


$recip = "contact\@divyaimpex.com" ;
$frm_ = "$smail" ;
$sbj_ = "Enquiry From Website - Www.verdeguatemala.net" ;
$hd_ = $recip.$frm_.$sbj ;
if (($hd =~ /(\n|\r)/m) || ($recip =~ /(@.*@)|(\.\.)|(@\.)|(\.@)|(^\.)/) || ($recip !~ /^.+\@(\[?)[a-zA-Z0-9\-\.]+\.([a-zA-Z0-9]+)(\]?)$/)) {
print "Fatal Error - Invalid email" ; 
exit 0; 
}

open (MAIL, "|$mail_prog -t");
print MAIL "To: $recip\n";
print MAIL "Reply-to: $frm_\n";
print MAIL "From: $frm_\n";
print MAIL "Subject: $sbj_\n";
print MAIL "\n\n";
print MAIL "To\n" ;
print MAIL "Divya Impex\n" ;
print MAIL "Udaipur\n" ;
print MAIL "\n" ;
print MAIL "Reference to visit of your website, we urgently need the following informations.\n" ;
print MAIL "\n" ;
print MAIL "-----------------\n" ;
print MAIL "Our Requirement\n" ;
print MAIL "-----------------\n" ;
print MAIL "".$srequire."\n" ;
print MAIL "\n" ;
print MAIL "-----------------\n" ;
print MAIL "\n" ;
print MAIL "Our Details are as follows:\n" ;
print MAIL "\n" ;
print MAIL "Our Company : ".$scompany."\n" ;
print MAIL "\n" ;
print MAIL "Address : ".$saddress."\n" ;
print MAIL "\n" ;
print MAIL "Phone : ".$sphone."\n" ;
print MAIL "\n" ;
print MAIL "Fax : ".$sfax."\n" ;
print MAIL "\n" ;
print MAIL "Email : ".$smail."\n" ;
print MAIL "\n" ;
print MAIL "Thanks\n" ;
print MAIL "\n" ;
print MAIL "".$sname."\n" ;
print MAIL "\n" ;
print MAIL "\n" ;
print MAIL "---------------\n" ;
print MAIL "\n" ;
print MAIL "\n\n";
close (MAIL);
print "Location: http://www.verdeguatemala.net/thanks.html\nURI: http://www.verdeguatemala.net/thanks.html\n\n" ;

sub PrintError { 
print "Content-type: text/html\n\n";
print $message ;
print "<p> Please use your browser's Back button to return to the form. </p>" ;

exit 0 ;
return 1 ; 
}
sub GetFormInput {

	(*fval) = @_ if @_ ;

	local ($buf);
	if ($ENV{'REQUEST_METHOD'} eq 'POST') {
		read(STDIN,$buf,$ENV{'CONTENT_LENGTH'});
	}
	else {
		$buf=$ENV{'QUERY_STRING'};
	}
	if ($buf eq "") {
			return 0 ;
		}
	else {
 		@fval=split(/&/,$buf);
		foreach $i (0 .. $#fval){
			($name,$val)=split (/=/,$fval[$i],2);
			$val=~tr/+/ /;
			$val=~ s/%(..)/pack("c",hex($1))/ge;
			$name=~tr/+/ /;
			$name=~ s/%(..)/pack("c",hex($1))/ge;

			if (!defined($field{$name})) {
				$field{$name}=$val;
			}
			else {
				$field{$name} .= ",$val";
				
				#if you want multi-selects to goto into an array change to:
				#$field{$name} .= "\0$val";
			}


		   }
		}
return 1;
}

