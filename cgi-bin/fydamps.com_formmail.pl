##############################################################################
# Define Variables                                                           #

$smtp_server = "10.0.1.131";

$mailprog = 'Geocel.Mailer';

@referers = ('www.fydamps.com/','fydamps.com/',);

@recipients = @referers;

@valid_ENV = ('REMOTE_HOST','REMOTE_ADDR','REMOTE_USER','HTTP_USER_AGENT','HTTP_REFERER');

$dmLogLevel = 3;

# Done                                                                       #
##############################################################################

# Check Referring URL
&check_url;

# Retrieve Date
&get_date;

# Parse Form Contents
&parse_form;

# Check Required Fields
&check_required;

# Return HTML Page or Redirect User
&return_html;

# Send E-Mail
&send_mail;

sub check_url {

    # Localize the check_referer flag which determines if user is valid.     #
    local($check_referer) = 0;

    # If a referring URL was specified, for each valid referer, make sure    #
    # that a valid referring URL was passed to FormMail.                     #

    if ($ENV{'HTTP_REFERER'}) {
	foreach $referer (@referers) {
	    if ($ENV{'HTTP_REFERER'} =~ m|https?://([^/]*)$referer|i) {
		$check_referer = 1;
		last;
	    }
	}
    }
    else {
	$check_referer = 1;
    }
    # If the HTTP_REFERER was invalid, send back an error.                   #
    if ($check_referer != 1) { &error('bad_referer') }
}

sub get_date {

    # Define arrays for the day of the week and month of the year.           #
    @days   = ('Sunday','Monday','Tuesday','Wednesday',
	       'Thursday','Friday','Saturday');
    @months = ('January','February','March','April','May','June','July',
		 'August','September','October','November','December');

    # Get the current time and format the hour, minutes and seconds.  Add    #
    # 1900 to the year to get the full 4 digit year.                         #
    ($sec,$min,$hour,$mday,$mon,$year,$wday) = (localtime(time))[0,1,2,3,4,5,6];
    $time = sprintf("%02d:%02d:%02d",$hour,$min,$sec);
    $year += 1900;

    # Format the date.                                                       #
    $date = "$days[$wday], $months[$mon] $mday, $year at $time";

}

sub parse_form {

    # Define the configuration associative array.                            #
    %Config = ('recipient','',          'subject','',
	       'username','',              'realname','',
	       'email','',              'name','',
	       'redirect','',           'bgcolor','',
	       'background','',         'link_color','',
	       'vlink_color','',        'text_color','',
	       'alink_color','',        'title','',
	       'sort','',               'print_config','',
	       'required','',           'env_report','',
	       'return_link_title','',  'return_link_url','',
	       'print_blank_fields','', 'missing_fields_redirect','',  'recipient2','',  'recipient3','',  'recipient4','');

    # Determine the form's REQUEST_METHOD (GET or POST) and split the form   #
    # fields up into their name-value pairs.  If the REQUEST_METHOD was      #
    # not GET or POST, send an error.                                        #
    if ($ENV{'REQUEST_METHOD'} eq 'GET') {
	# Split the name-value pairs
	@pairs = split(/&/, $ENV{'QUERY_STRING'});
    }
    elsif ($ENV{'REQUEST_METHOD'} eq 'POST') {
	# Get the input
	read(STDIN, $buffer, $ENV{'CONTENT_LENGTH'});
 
	# Split the name-value pairs
	@pairs = split(/&/, $buffer);
    }
    else {
	&error('request_method');
    }

    # For each name-value pair:                                              #
    foreach $pair (@pairs) {

	# Split the pair up into individual variables.                       #
	local($name, $value) = split(/=/, $pair);
 
	# Decode the form encoding on the name and value variables.          #
	$name =~ tr/+/ /;
	$name =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack("C", hex($1))/eg;

	$value =~ tr/+/ /;
	$value =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack("C", hex($1))/eg;

	# If they try to include server side includes, erase them, so they
	# aren't a security risk if the html gets returned.  Another 
	# security hole plugged up.
	$value =~ s/<!--(.|\n)*-->//g;

	# If the field name has been specified in the %Config array, it will #
	# return a 1 for defined($Config{$name}}) and we should associate    #
	# this value with the appropriate configuration variable.  If this   #
	# is not a configuration form field, put it into the associative     #
	# array %Form, appending the value with a ', ' if there is already a #
	# value present.  We also save the order of the form fields in the   #
	# @Field_Order array so we can use this order for the generic sort.  #
	if (defined($Config{$name})) {
	    $Config{$name} = $value;
	}
	else {
	    if ($Form{$name} && $value) {
		$Form{$name} = "$Form{$name}, $value";
	    }
	    elsif ($value) {
		push(@Field_Order,$name);
		$Form{$name} = $value;
	    }
	}
    }

    # The next six lines remove any extra spaces or new lines from the       #
    # configuration variables, which may have been caused if your editor     #
    # wraps lines after a certain length or if you used spaces between field #
    # names or environment variables.                                        #
    $Config{'required'} =~ s/(\s+|\n)?,(\s+|\n)?/,/g;
    $Config{'required'} =~ s/(\s+)?\n+(\s+)?//g;
    $Config{'env_report'} =~ s/(\s+|\n)?,(\s+|\n)?/,/g;
    $Config{'env_report'} =~ s/(\s+)?\n+(\s+)?//g;
    $Config{'print_config'} =~ s/(\s+|\n)?,(\s+|\n)?/,/g;
    $Config{'print_config'} =~ s/(\s+)?\n+(\s+)?//g;

    # Split the configuration variables into individual field names.         #
    @Required = split(/,/,$Config{'required'});
    @Env_Report = split(/,/,$Config{'env_report'});
    @Print_Config = split(/,/,$Config{'print_config'});
}

sub check_required {

    # Localize the variables used in this subroutine.                        #
    local($require, @error); 
    
    if ($Config{'username'} =~ /(\n|\r)/m) {
        &error('no_email');
    }
    
    if ($Config{'recipient'} =~ /(\n|\r)/m) {
        &error('no_recipient');
    }
    
    if (!$Config{'username'}) {
        if (!defined(%Form)) { &error('no_email') }
        else                 { &error('no_email') }
    }
    
    if (!$Config{'recipient'}) {
        if (!defined(%Form)) { &error('bad_referer') }
        else                 { &error('no_recipient') }
    }
    else {
        # This block of code requires that the recipient address end with    #
        # a valid domain or e-mail address as defined in @recipients.        #
        $valid_recipient = 0;
        foreach $send_to (split(/,/,$Config{'recipient'})) {
            foreach $recipient (@recipients) {
                if ($send_to =~ /$recipient$/i) {
                    push(@send_to,$send_to); last;
                }
            }
        }
        if ($#send_to < 0) { &error('no_recipient') }
        $Config{'recipient'} = join(',',@send_to);
    }

    # For each require field defined in the form:                            #
    foreach $require (@Required) {

        # If the required field is the email field, the syntax of the email  #
        # address if checked to make sure it passes a valid syntax.          #
        if ($require eq 'email' && !&check_email($Config{$require})) {
            push(@error,$require);
        }

        # Otherwise, if the required field is a configuration field and it   #
        # has no value or has been filled in with a space, send an error.    #
        elsif (defined($Config{$require})) {
            if (!$Config{$require}) {
                push(@error,$require);
            }
        }

        # If it is a regular form field which has not been filled in or      #
        # filled in with a space, flag it as an error field.                 #
        elsif (!$Form{$require}) {
            push(@error,$require);
        }
    }

    # If any error fields have been found, send error message to the user.   #
    if (@error) { &error('missing_fields', @error) }
}

sub return_html {
    # Local variables used in this subroutine initialized.                   #
    local($key,$sort_order,$sorted_field);

    # If redirect option is used, print the redirectional location header.   #
   if ($Config{'redirect'}) {
        print "Location: $Config{'redirect'}\n\n";
    }

    # Otherwise, begin printing the response page.                           #
    else {

	# Print HTTP header and opening HTML tags.                           #

if(defined(IIS_MODE)) { print "HTTP/1.0 200 OK\n"; }

	print "Content-type: text/html\n\n";
	print "<html>\n <head>\n";

	# Print out title of page                                            #
	if ($Config{'title'}) { print "  <title>$Config{'title'}</title>\n" }
	else                  { print "  <title>Thank You</title>\n"        }

	print " </head>\n <body";

	# Get Body Tag Attributes                                            #
	&body_attributes;

	# Close Body Tag                                                     #
	print ">\n  <center>\n";

	# Print custom or generic title.                                     #
	if ($Config{'title'}) { print "   <h1>$Config{'title'}</h1>\n" }
	else { print "   <h2>Thank You</h2>\n" }

	print "</center>\n";

	print "Below is what you submitted to $Config{'recipient'} on ";
	print "$date<p><hr size=1 width=90\%><p>\n";

	# Sort alphabetically if specified:                                  #
	if ($Config{'sort'} eq 'alphabetic') {
	    foreach $field (sort keys %Form) {

		# If the field has a value or the print blank fields option  #
		# is turned on, print out the form field and value.          #
		if ($Config{'print_blank_fields'} || $Form{$field}) {
		    print "<b>$field:</b> $Form{$field}<p>\n";
		}
	    }
	}

	# If a sort order is specified, sort the form fields based on that.  #
	elsif ($Config{'sort'} =~ /^order:.*,.*/) {

	    # Set the temporary $sort_order variable to the sorting order,   #
	    # remove extraneous line breaks and spaces, remove the order:    #
	    # directive and split the sort fields into an array.             #
	    $sort_order = $Config{'sort'};
	    $sort_order =~ s/(\s+|\n)?,(\s+|\n)?/,/g;
	    $sort_order =~ s/(\s+)?\n+(\s+)?//g;
	    $sort_order =~ s/order://;
	    @sorted_fields = split(/,/, $sort_order);

	    # For each sorted field, if it has a value or the print blank    #
	    # fields option is turned on print the form field and value.     #
	    foreach $sorted_field (@sorted_fields) {
		if ($Config{'print_blank_fields'} || $Form{$sorted_field}) {
		    print "<b>$sorted_field:</b> $Form{$sorted_field}<p>\n";
		}
	    }
	}

	# Otherwise, default to the order in which the fields were sent.     #
	else {

	    # For each form field, if it has a value or the print blank      #
	    # fields option is turned on print the form field and value.     #
	    foreach $field (@Field_Order) {
		if ($Config{'print_blank_fields'} || $Form{$field}) {
		    print "<b>$field:</b> $Form{$field}<p>\n";
		}
	    }
	}

	print "<p><hr size=1 width=90%><p>\n";

	# Check for a Return Link and print one if found.                    #
	if ($Config{'return_link_url'} && $Config{'return_link_title'}) {
	    print "<ul>\n";
	    print "<li><a href=\"$Config{'return_link_url'}\">$Config{'return_link_title'}</a>\n";
	    print "</ul>\n";
	}
	 
}

###
## If you have an existing FormMail script you want to convert you can copy this
## file or look at the code below as an example.
#

sub send_mail {

    # Localize variables used in this subroutine.                            #
    local($print_config,$key,$sort_order,$sorted_field,$env_report);
	
	my $script_url;
    my $client_ip;

    $script_url = "http://" . $ENV{'SERVER_NAME'} . ":" .
                  $ENV{'SERVER_PORT'} . $ENV{'SCRIPT_NAME'};

    $client_ip = "[" . $ENV{'REMOTE_ADDR'} . "]";
    
    $referrer = "[" . $ENV{'HTTP_REFERER'} . "]";
    
    use OLE;

    $DevMailer = CreateObject OLE 'Geocel.Mailer';

	if(! $DevMailer)
	{
		print "<P><CENTER><font color=\"red\" size=+2><b>Could not create DevMailer Object.</B></font> <BR><B>Look Below for Troubleshooting Help!</B></CENTER><P>";
		print "<B>Be Sure the following packages are installed:</B><BR><UL><LI><A HREF=\"http://www.activestate.com\">ActiveState Active Perl 5.x</A><BR><LI><A HREF=\"http://www.geocel.com/devmailer/\">Geocel DevMailer 1.x</A></UL><P>";		
		print "<B>Troubleshooting tips:</B><BR>\n";		
		print "<UL><LI>This error is caused because Perl fails to load a software object.  This can be because DevMailer is not properly installed, or because this server is using an unsupported version of perl.\n";		
		print "<LI>If you've checked the above things, try moving DVMAILER.DLL to your CGI-BIN directory and register it there.  If your server has tight file security, the web server may not have permission to use DVMAILER.DLL in its own directory.\n";		
		print "</UL>\n";
		return;
	}
	
	#added to make changing the loglevel easier in header.
	$DevMailer->{LogLevel} = $dmLogLevel;

	# Set Up SMTP Server
	$DevMailer->AddServer ($smtp_server,25);

	# Add Recipient
    $DevMailer->AddRecipient ($Config{'recipient'},"");

    # Add Recipient 2
    $DevMailer->AddRecipient ($Config{'recipient2'},"");
    
    # Add Recipient 3
    $DevMailer->AddRecipient ($Config{'recipient3'},"");
    
    # Add Recipient 4
    $DevMailer->AddRecipient ($Config{'recipient4'},"");

	# Set From: Name
    if ($Config{'realname'})
    {
		$DevMailer->{FromName}  = $Config{'realname'};
	}else 
	{
		$DevMailer->{FromName}  = $Config{'name'};
	}

    	# Set From: Email Address
	# Changed 06/10/99 to prevent missing sender address

    	if($Config{'username'})
	{
		$DevMailer->{FromAddress}  = "$Config{'username'}";
	} else 
	{
		$DevMailer->{FromAddress}  = "$Config{'email'}";
	}

    # Check for Message Subject
    if ($Config{'subject'}) { $DevMailer->{Subject} = $Config{'subject'}; }
    else                    { $DevMailer->{Subject} = "Web Site Form Submission"; }

	$DevMailer->AddRawHeader("X-Generated-By", "Matt Wright's FormMail.pl v1.9s-p7");
	$DevMailer->AddRawHeader("X-Script-URL", "$script_url");
	
	$DevMailer->AddRawHeader("X-Originating-IP", "$client_ip");
	
	$DevMailer->AddRawHeader("HTTP_REFERER", "$referrer");

    $dmbody="";
	
    $dmbody = $dmbody . "An email was sent to you by $Config{'realname'} \r\n";
    $dmbody = $dmbody . "($Config{'username'}) on $date\r\n";
    $dmbody = $dmbody . "-" x 60 . "\r\n\r\n";

    if (@Print_Config) {
	foreach $print_config (@Print_Config) {
	    if ($Config{$print_config}) {
		    $dmbody = $dmbody . "$print_config: $Config{$print_config}\r\n\r\n";
	    }
	}
    }

    # Sort alphabetically if specified:                                      #
    if ($Config{'sort'} eq 'alphabetic') {
	foreach $field (sort keys %Form) {

	    # If the field has a value or the print blank fields option      #
	    # is turned on, print out the form field and value.              #
	    if ($Config{'print_blank_fields'} || $Form{$field} ||
		$Form{$field} eq '0') {
		$dmbody = $dmbody . "$field: $Form{$field}\r\n\r\n";
	    }
	}
    }

    # If a sort order is specified, sort the form fields based on that.      #
    elsif ($Config{'sort'} =~ /^order:.*,.*/) {

	# Remove extraneous line breaks and spaces, remove the order:        #
	# directive and split the sort fields into an array.                 #
	$Config{'sort'} =~ s/(\s+|\n)?,(\s+|\n)?/,/g;
	$Config{'sort'} =~ s/(\s+)?\n+(\s+)?//g;
	$Config{'sort'} =~ s/order://;
	@sorted_fields = split(/,/, $Config{'sort'});

	# For each sorted field, if it has a value or the print blank        #
	# fields option is turned on print the form field and value.         #
	foreach $sorted_field (@sorted_fields) {
	    if ($Config{'print_blank_fields'} || $Form{$sorted_field} ||
		$Form{$sorted_field} eq '0') {
		$dmbody = $dmbody . "$sorted_field: $Form{$sorted_field}\r\n\r\n";
	    }
	}
    }

    # Otherwise, default to the order in which the fields were sent.         #
    else {

	# For each form field, if it has a value or the print blank          #
	# fields option is turned on print the form field and value.         #
	foreach $field (@Field_Order) {
	    if ($Config{'print_blank_fields'} || $Form{$field} ||
		$Form{$field} eq '0') {
		$dmbody = $dmbody . "$field: $Form{$field}\r\n\r\n";
	    }
	}
    }

    $dmbody = $dmbody . "-" x 60 . "\r\n\r\n";

   
	$DevMailer->{Body} = $dmbody;
	$success = $DevMailer->Send();

	if($success) {
		# successfully sent
	} 
	else {	
		if($DevMailer->{Queued})
		{
			print "Message Queued for delivery";
		} else
		{
			print "<B>Could not send message due to an internal problem within the form.
			Please contact the web site administrator so that they may fix this problem. 
			Please use the email link on our homepage for now to send your message.<br><br>
			
			Thank You...</B>";
		}
	}
}

sub check_email {
    # Initialize local email variable with input to subroutine.              #
    $email = $_[0];

    # If the e-mail address contains:                                        #
    if ($email =~ /(@.*@)|(\.\.)|(@\.)|(\.@)|(^\.)/ ||

	# the e-mail address contains an invalid syntax.  Or, if the         #
	# syntax does not match the following regular expression pattern     #
	# it fails basic syntax verification.                                #

	$email !~ /^.+\@(\[?)[a-zA-Z0-9\-\.]+\.([a-zA-Z]{2,3}|[0-9]{1,3})(\]?)$/) {

	# Basic syntax requires:  one or more characters before the @ sign,  #
	# followed by an optional '[', then any number of letters, numbers,  #
	# dashes or periods (valid domain/IP characters) ending in a period  #
	# and then 2 or 3 letters (for domain suffixes) or 1 to 3 numbers    #
	# (for IP addresses).  An ending bracket is also allowed as it is    #
	# valid syntax to have an email address like: user@[255.255.255.0]   #

	# Return a false value, since the e-mail address did not pass valid  #
	# syntax.                                                            #
	return 0;
    }

    else {

	# Return a true value, e-mail verification passed.                   #
	return 1;
    }
}


sub GetTempFileName {

	$path = $_[0];
	$prefix = $_[1];

	# Get a random number
	
	# First, seed the random number generator
	srand;

	# Then get a random # for which a file name can be created
	$done = 0;
	$tempfile = "";
	while (!$done)
	{
		$randNum = int(rand(999999));
		$tempfile = "$path\\$prefix$randNum.tmp";
		open(TEMP, "<$tempfile") or $done = 1;
		close(TEMP);
	}
	
	return $tempfile;
}


sub body_attributes {
    # Check for Background Color
    if ($Config{'bgcolor'}) { print " bgcolor=\"$Config{'bgcolor'}\"" }

    # Check for Background Image
    if ($Config{'background'}) { print " background=\"$Config{'background'}\"" }

    # Check for Link Color
    if ($Config{'link_color'}) { print " link=\"$Config{'link_color'}\"" }

    # Check for Visited Link Color
    if ($Config{'vlink_color'}) { print " vlink=\"$Config{'vlink_color'}\"" }

    # Check for Active Link Color
    if ($Config{'alink_color'}) { print " alink=\"$Config{'alink_color'}\"" }

    # Check for Body Text Color
    if ($Config{'text_color'}) { print " text=\"$Config{'text_color'}\"" }
}

sub error { 
    # Localize variables and assign subroutine input.                        #
    local($error,@error_fields) = @_;
    local($host,$missing_field,$missing_field_list);

    if ($error eq 'bad_referer') {
	if ($ENV{'HTTP_REFERER'} =~ m|^https?://([\w\.]+)|i) {
	    $host = $1;

if(defined(IIS_MODE)) { print "HTTP/1.0 200 OK\n"; }

	    print <<"(END ERROR HTML)";
Content-type: text/html

<html>
 <head>
  <title>Bad Referrer - Access Denied</title>
 </head>
 <body bgcolor=#FFFFFF text=#000000>
  <center>
   <table border=0 width=600 bgcolor=#9C9C9C>
    <tr><th><font size=+2>Bad Referrer - Access Denied</font></th></tr>
   </table>
   <table border=0 width=600 bgcolor=#CFCFCF>
    <tr><td>The form attempting to use FormMail resides at <tt>$ENV{'HTTP_REFERER'}</tt>, is not allowed to access
     this cgi script.<p>

     If you are attempting to configure FormMail to run with this form, you need
     to add the following to \@referers, explained in detail in the README file.<p>

     Add <tt>'$host'</tt> to your <tt><b>\@referers</b></tt> array.<hr size=1>
     
    </td></tr>
   </table>
  </center>
 </body>
</html>
(END ERROR HTML)
	}
	else {

if(defined(IIS_MODE)) { print "HTTP/1.0 200 OK\n"; }

	    print <<"(END ERROR HTML)";
Content-type: text/html

<html>
 <head>
  <title>FormMail v1.9</title>
 </head>
 <body bgcolor=#FFFFFF text=#000000>
  <center>
   <table border=0 width=600 bgcolor=#9C9C9C>
    <tr><th><font size=+2>FormMail</font></th></tr>
   </table>
   <table border=0 width=600 bgcolor=#CFCFCF>
    <tr><th><tt><font size=+1>Copyright 1995 - 1997 Matt Wright<br>
	Version 1.6 - Released May 02, 1997<br>
	A Free Product of <a href="http://www.worldwidemart.com/scripts/">Matt's Script Archive,
	Inc.</a><br>
	Windows 95/98/NT Port by <A HREF="http://www.geocel.com/">Geocel International, Inc.</A></font></tt></th></tr>
   </table>
  </center>
 </body>
</html>
(END ERROR HTML)
	}
    }

    elsif ($error eq 'request_method') {

if(defined(IIS_MODE)) { print "HTTP/1.0 200 OK\n"; }

	print <<"(END ERROR HTML)";
Content-type: text/html

<html>
 <head>
  <title>Error: Request Method</title>
 </head>
 <body bgcolor=#FFFFFF text=#000000>
  <center>
   <table border=0 width=600 bgcolor=#9C9C9C>
    <tr><th><font size=+2>Error: Request Method</font></th></tr>
   </table>
   <table border=0 width=600 bgcolor=#CFCFCF>
    <tr><td>The Request Method of the Form you submitted did not match
     either <tt>GET</tt> or <tt>POST</tt>.  Please check the form and make sure the
     <tt>method=</tt> statement is in upper case and matches <tt>GET</tt> or <tt>POST</tt>.<p>

    </td></tr>
   </table>
  </center>
 </body>
</html>
(END ERROR HTML)
    }

	elsif ($error eq 'no_email') {

if(defined(IIS_MODE)) { print "HTTP/1.0 200 OK\n"; }

	    print <<"(END ERROR HTML)";
Content-type: text/html

<html>
 <head>
  <title>Error: No Email Address/Non-Valid email</title>
 </head>
 <body bgcolor=#FFFFFF text=#000000>
  <center>
   <table border=0 width=600 bgcolor=#9C9C9C>
    <tr><th><font size=+2>Error: No Email Address/Non-Valid email</font></th></tr>
   </table>
   <table border=0 width=600 bgcolor=#CFCFCF>
    <tr><td>No email address or a non-valid email was specified in the data sent.  Please
     make sure you have filled in the 'email' form field with an e-mail
     address that is valid. <hr size=1>
    </td></tr>
   </table>
  </center>
 </body>
</html>
(END ERROR HTML)
    }
    
    elsif ($error eq 'no_recipient') {

if(defined(IIS_MODE)) { print "HTTP/1.0 200 OK\n"; }

	    print <<"(END ERROR HTML)";
Content-type: text/html

<html>
 <head>
  <title>Error: No Recipient/Wrong email Domain</title>
 </head>
 <body bgcolor=#FFFFFF text=#000000>
  <center>
   <table border=0 width=600 bgcolor=#9C9C9C>
    <tr><th><font size=+2>No Recipient in Form/Wrong email Domain</font></th></tr>
   </table>
   <table border=0 width=600 bgcolor=#CFCFCF>
    <tr><td>No Recipient was specified in the data sent.  
    Please contact web site administrator so they may fix this problem. 
    Use email link on our homepage to send your message.<hr size=1>

    </td></tr>
   </table>
  </center>
 </body>
</html>
(END ERROR HTML)
    }

    elsif ($error eq 'missing_fields') {
	if ($Config{'missing_fields_redirect'}) {
	    print "Location: $Config{'missing_fields_redirect'}\n\n";
	}
	else {
	    foreach $missing_field (@error_fields) {
		$missing_field_list .= "      <li>$missing_field\n";
	    }

if(defined(IIS_MODE)) { print "HTTP/1.0 200 OK\n"; }

	    print <<"(END ERROR HTML)";
Content-type: text/html

<html>
 <head>
  <title>Error: Blank Fields</title>
 </head>
  <center>
   <table border=0 width=600 bgcolor=#9C9C9C>
    <tr><th><font size=+2>Error: Blank Fields</font></th></tr>
   </table>
   <table border=0 width=600 bgcolor=#CFCFCF>
    <tr><td>The following fields were left blank in your submission form:<p>
     <ul>
$missing_field_list
     </ul><br>

     These fields must be filled in before you can successfully submit the form.<p>
     Please use your browser's back button to return to the form and try again.<hr size=1>
    </td></tr>
   </table>
  </center>
 </body>
</html>
(END ERROR HTML)
	}
    }
   exit (0);
}
}
