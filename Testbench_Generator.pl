#!/usr/bin/perl -w
# pp -o Testbench_Generator.exe Testbench_Generator.pl

use strict;
use warnings;
use 5.010;

use Tk;
use Tk::NoteBook;
use Tk::Dialog;
use Tk::DialogBox;
use Tk::BrowseEntry;
use File::Basename;
use Tk::NoteBook;
use Tk::TableMatrix;
use List::MoreUtils qw(first_index);

my $current_file=();

our $top = MainWindow->new;
$top->configure(-title=> "Automatic VHDL Testbench Generator");
$top->geometry("650x340+0+0");
my $nb = $top->NoteBook( )->pack(-expand => 1, -fill => 'both'); 
my $mw = $nb->add('page1', -label => 'Main'); 
my $mw2 = $nb->add('page2', -label => 'Truth Table'); 





######################## Ports ################################################

my $input_ports = "Ports";

$mw->Label(-text => 'Input Ports :')->place(-x => 10, -y => 65);
$mw->Label(-text => 'Vector Information : ')->place(-x => 10, -y => 95); 
my $text_Vector_Information = $mw->Text(qw/-width 35 -height 1/) ->place(-x => 110, -y => 95);

my $fr1 = $mw->Frame()->place(-x => 75, -y => 60);
my $om1 = $fr1->Optionmenu(-variable => \$input_ports)->pack();
#print "$om1"; 





#################### File Name and Upload Button ##############################

$mw->Button(
    -text    => 'Upload',
    -command => \&open_vhdl,
)->place(-x => 510, -y => 13);

$mw->Label(-text => 'File Name :')->place(-x => 90, -y => 15);
my $text = $mw->Text(qw/-width 50 -height 1/) ->place(-x => 150, -y => 15);

#################### Global Variable ##############################
my ($file);
my $new_file_vhd;
my $year;
my $month;
my $day;
my $author;
my $new_file;
my @ports;
my $out3;
my $out2;
my @sig_in;
my @Vector_Information;
my @Vector_Information2;

my $no_signal_input = 0;
my @signal_input;
my $no_signal_cycle = 0;
my @signal_cycle;
my @signal_Bits;
my @signal_input_type;
my @signal_Bits_Timing;
my @signal_Timing;
my @signal_input_bits;
my @signal_input_delay;
my $no_truth_table = 0;
my @signal_truthTable;
my @single_bits_clk_port_yesno;
my @single_bits_clk_port;
my @multiple_bits_clk_port_yesno;
my @multiple_bits_clk_port;
my @multiple_bits_time_metric;
my @single_bits_time_metric;
my @reset_time_metric;
my @reset_clk_port_yesno;
my @reset_clk_port;

my $no_reset = 0;
my @reset_port;
my @reset_cycle;
my @reset_on;
my @reset_off;

my $no_clock = 0;
my @clock;
my @clock_port;
my @clock_DC;
my @clock_time_metric;

my @input_truthTable;
my $input_delay;
my $input_delay_metric;


sub open_vhdl
{
########################## Reset All Variable ########################
($file) = ();
$new_file_vhd = ();
$year = ();
$month = ();
$day = ();
$author = ();
$new_file = ();
@ports = ();
$out3 = ();
$out2 = ();
@sig_in = ();
@Vector_Information = ();
@Vector_Information2 = ();

$no_signal_input = 0;
@signal_input = ();
$no_signal_cycle = 0;
@signal_cycle = ();
@signal_input_type = ();
@signal_Bits_Timing = ();
@signal_Timing = ();
@signal_input_bits = ();
@signal_input_delay = ();
$no_truth_table = 0;
@signal_truthTable = ();

@single_bits_clk_port_yesno = ();
@single_bits_clk_port = ();
@multiple_bits_clk_port_yesno = ();
@multiple_bits_clk_port = ();
@multiple_bits_time_metric = ();
@single_bits_time_metric = ();
@reset_time_metric = ();
@reset_clk_port_yesno = ();
@reset_clk_port = ();

$no_reset = 0;
@reset_port = ();
@reset_cycle = ();
@reset_on = ();
@reset_off = ();

$no_clock = 0;
@clock = ();
@clock_DC = ();
@clock_port = ();
@clock_time_metric = ();

@input_truthTable = ();
$input_delay = 0;
$input_delay_metric = 0;





########################## Open VHDL ########################
   	my @types =
       		(["VHDL files", [qw/.vhd /]],
        	["All files",        '*'],
       	);
   	$current_file = $mw->getOpenFile(-filetypes => \@types);

   	$text->delete('1.0', 'end');
   	$text->insert('end', "$current_file");

   	open(inF, $current_file) or dienice ("file open failed");
   	my @data = <inF>;
   	close(inF);

   	($file) = fileparse $current_file;

   	print "filename: $file\n";

	# Make Date int MM/DD/YYYY
	my $year      = 0;
	my $month     = 0;
	my $day       = 0;
	($day, $month, $year) = (localtime)[3,4,5];


	# Grab username from PC:
	$author = "$^O user";
	if ($^O =~ /mswin/i)
	{ 
  	$author= $ENV{USERNAME} if defined $ENV{USERNAME};
	}
	else
	{ 
  	$author = getlogin();
	}


	#	Strip newlines
	foreach my $i (@data) {
		chomp($i);
		$i =~ s/--.*//;		#strip any trailing -- comments
	}

	#	initialize counters
	my $lines = scalar(@data);		#number of lines in file
	my $line = 0;
	my $entfound = -1;

	#	find 'entity' left justified in file
	for ($line = 0; $line < $lines; $line++) {
		if ($data[$line] =~ m/^entity/) {
			$entfound = $line;
			$line = $lines;	#break out of loop
		}
	}

	# find 'end $file', so that when we're searching for ports we don't include local signals.
	my $entendfound = 0;
	$file =~ s/\.vhd$//;
	for ($line = 0; $line < $lines; $line++) {
		if ($data[$line] =~ m/^end $file/) {
			$entendfound = $line;
			$line = $lines;	#break out of loop
		}
	}


	#	if we didn't find 'entity' then quit
	if ($entfound == -1) {
		print("Unable to instantiate-no occurance of 'entity' left justified in file.\n");
		exit;
	}

	#find opening paren for port list
	$entendfound = $entendfound + 1;
	my $pfound = -1;

	# Remove entity line and port (
	for ($line = $entfound; $line < $entendfound; $line++) { #start looking from where we found module
		$data[$line] =~ s/--.*//;		#strip any trailing --comment
	
        	if ($data[$line] =~ m/\(/) {		# 0x28 is '('
			$pfound = $line;
                	$data[$line] =~ s/.*\x28//;	# remove "port ("
			print "$data[$line]\n";
			$line = $entendfound;	# break out of loop		
		}
	}

	#	if couldn't find '(', exit
	if ($pfound == -1) {
		print("Unable to instantiate-no occurance of '(' after module keyword.\n");
		exit;
	}

	@ports = ();
	# print a(or b) : in  STD_LOGIC; sum(or carry) : out  STD_LOGIC;
	for ($line = $pfound; $line < $entendfound; $line++) {
		$data[$line] =~ s/--.*//;		#strip any trailing --comment
		next if not $data[$line] =~ /:.*/;
		$data[$line] =~ s/^\s+|\s+$//; # trim right and left space
        	push @ports , $data[$line];
		#print "$data[$line]";
	}

	my @portsInOut = ();
	@portsInOut = @ports;
	my @portlines1;
	my $count_ports = 0;
	foreach my $i (@portsInOut) {
		$i =~ s/ in//;
		$i =~ s/ out//;

		if( $count_ports == $#portsInOut ) {
			chop($i);
			chop($i);
			$i =~ s|/?$|;|;
  		}
  	push @portlines1, "\tsignal tb_$i";
	$count_ports++;
	}
	
	$out3 = ();
	$out3 = join "\n", @portlines1;

	#print out instantiation
	#print ("component $file\n");	#print first line
	#print " port (\n";		#print second line
	#my $out= join "\n", @ports;
	#print ("$out\t\n\t\nend component;\n"); #print ports and last couple of lines

	# Create the module instantiation.  A future enhancement would be to call the script vhdl_inst.pl instead.
	my @ports2;
	my @inOut;
	for ($line = $pfound; $line < $entendfound; $line++) {
		$data[$line] =~ s/--.*//;	# strip any trailing --comment

		#   next if not $data[$line] =~ /:.*;/;
		$data[$line] =~ s/^/ /mg; 	# add space at the beginning of line

		if ($data[$line] =~ /\s+(\w+)\s+:/)
		{
			push @ports2, $1;
			#print "\n$1";
		
		}

		if ($data[$line] =~ /\s+(\w+)\s+STD_LOGIC/)
		{
			push @inOut, $1;
			#print "\n$1";
		
		}

		if ($data[$line] =~ /\sin\s+(\w+)/)
		{
			if ($data[$line] =~ /STD_LOGIC_VECTOR\s*(.+)$/)
			{
				push @Vector_Information, "STD_LOGIC_VECTOR $1";	
			}	
			else	
			{
				push @Vector_Information, $1;
			}
		}
	}

	#foreach my $i (@Vector_Information) {
 	# push @Vector_Information2, "$i";
	#}

	my @portlines2;
	foreach my $i (@ports2) {
 	 push @portlines2, "$i \t=> tb_$i";
	}

	$out2 = ();
	$out2 = join ",\n\t", @portlines2;

	# check to make sure that the file doesn't exist.
	$new_file = join "_", $file, "tb";
	$new_file_vhd = join ".",$new_file,"vhd";
	#die "Oops! A file called '$new_file.vhd' already exists.\n" if -e $new_file_vhd;

	my $in_count = 1;
	my $out_count = 1;
	my $count = 0;	

	foreach my $i (@inOut) {
		if ($i =~ "in")
		{
			print "\n Signals input $in_count: tb_$ports2[$count]";
			$sig_in[$in_count - 1] = $ports2[$count];
			$in_count = $in_count + 1;
		}
		elsif ($i =~ "out")
		{
			print "\n Signals output $out_count: tb_$ports2[$count]";
			$out_count = $out_count + 1;
		}
	$count = $count + 1;
	}
	print "\n";

	$om1 = $fr1->destroy;
	$fr1 = $mw->Frame()->place(-x => 75, -y => 60);
	$om1 = $fr1->Optionmenu(
	-variable => \$input_ports,
	-options => \@sig_in,
    	-command  => \&option_menu_changed,
	)->pack;
}

sub option_menu_changed {
	my $entry = ();
	my $array_num =  first_index { $_ eq $input_ports } @sig_in;
	#say "\nInput Ports: $input_ports";
	#say "\nVector Information: $Vector_Information[$array_num]";
	
   	$text_Vector_Information->delete('1.0', 'end');
   	$text_Vector_Information->insert('end', "$Vector_Information[$array_num]");
}





######################## Signal Checkbox ################################################

$mw->Label(-text => 'Input Type :')->place(-x => 240, -y => 45); 

my @types1 = ('Clock','Reset','Signal');
my $input_type;
for my $itype1 (@types1) {
    my $cb1 = $mw->Radiobutton(
        -text     => $itype1,
        -variable => \$input_type,
        -value    => $itype1,
        -font     => ['fixed', 10],
	-command  => \&do_on_select1,
    );
    $cb1->pack(-side => 'right',-anchor => 'ne',-padx => 45, -pady => 65);
}

sub do_on_select1 {
	#say "\nInput Type : $input_type";
}





################### Signal Type (DC,Bits,Truth_Table) #####################################                                                                               

$mw->Label(-text => 'Signal', -font => ['bold',10])->place(-x => 60, -y => 120);
### No. of Cycle ###
$mw->Label(-text => 'No. Cycle :')->place(-x => 10, -y => 150);
my $entry = $mw->Entry(
    -font => ['fixed', 10],
    -width   => 10,
);
$entry->place(-x => 70, -y => 150);

my $btn = $mw->Button(
    -text    => 'Saved',
    -font    => ['fixed', 10],
    -command => \&do_on_clicked_S,
);
$btn->place(-x => 100, -y => 147);

sub do_on_clicked_S {
    #print("\nNo. Signal Cycle: ",$entry->get);

    return $entry->get;
}

$mw->Label(-text => 'Signal Type :')->place(-x => 10, -y => 190); 





################# Duty Cycle, Bits, Truth Table ###########################################

my @types2 = ('Truth Table','Vector Bits','Single Bits');
my $signal_type;
for my $itype2 (@types2) {
    my $cb2 = $mw->Radiobutton(
        -text     => $itype2,
        -variable => \$signal_type,
        -value    => $itype2,
        -font     => ['fixed', 10],
	-command  => \&do_on_select2, 
   );
    $cb2->pack(-side => 'bottom',-anchor => 'w',-pady => 3,-padx => 10);
}


my @entry_Bit_Bits;
my @entry_Bit_Delay;
my @entryBits;
my @entryBitsTiming;
my @entryTiming;
my $time_metric1;
my $time_metric2;
my $clk_rst1;
my $option_menu_clk1;
my $clk_rst2;
my $option_menu_clk2;

sub do_on_select2 {
    	#print "\nSignal Type: $signal_type\n";

######################## Single Bits ########################################
 	if ($signal_type =~ "Single Bits"){

		my $btn1 = $mw->Button(
    			-text    => 'Timing Details',
    			-font    => ['fixed', 10],
    			-command => \&do_on_click1,
		);
		$btn1->place(-x => 110, -y => 245);

		sub do_on_click1 {
   			my $dialog1 = $mw->DialogBox(
        			-title   => 'Timing Details',
        			-popover => $mw,
        			-buttons => ['Confirm', 'No'],
    			);

			my @clock_timings1 = ('Timing based on clock ports');
			for my $clock_timing1 (@clock_timings1) {
   				$clk_rst1 = 0;
   				my $cb_clk1 = $dialog1->Checkbutton(
        				-text     => $clock_timing1,
        				-variable => \$clk_rst1,
					-command => \&do_on_click_clk1,
        				-font     => ['fixed', 10]
    					);
    				$cb_clk1->pack;
			}

			sub do_on_click_clk1 {
    				#print("Clicked\n");
        			#printf("%s\n",$clk_rst1); 
    				#print("----\n");
			}

			$option_menu_clk1 = 'Choose Clock Port';

			my $option_clk1 = $dialog1->Optionmenu(
    				-variable => \$option_menu_clk1,
    				-options  => \@clock_port,
			);
			$option_clk1->pack(); 


			###################### Time Metric #######################
			$dialog1->add("Label", -text => 'Time Metric :', -font => ['fixed', 10])->pack();

			$time_metric1 = 'ns';

			my $time_metric_entry1 = $dialog1->BrowseEntry(
    				-variable => \$time_metric1,
   				-state => 'readonly',
    				-command => \&time_metric_changed1,
    				-choices => [qw(ns us ms)],
			);

			$time_metric_entry1->pack();	

			sub time_metric_changed1 {
    				#say "Option menu set to: $time_metric1"
			}

			###################### Bits and Delay #######################
   		 	my $cycle_ports = do_on_clicked_S();

    			for (my $i = 0 ; $i <= $cycle_ports - 1 ; $i++) {
    				$dialog1->add("Label", -text => 'Single Bits : ', -font => ['fixed', 10])->pack();
    				$entryBits[$i] = $dialog1->add("Entry", -width => 64, -font => ['fixed', 10],)->pack();

    				$dialog1->add("Label", -text => 'Delay between each bits : ', -font => ['fixed', 10])->pack();
    				$entryBitsTiming[$i] = $dialog1->add("Entry", -width => 64, -font => ['fixed', 10],)->pack();

				if ($i < $cycle_ports - 1) {
    					$dialog1->add("Label", -text => 'Delay Timing between each data: ', -font => ['fixed', 10])->pack();
    					$entryTiming[$i] = $dialog1->add("Entry", -width => 64, -font => ['fixed', 10],)->pack();
				}   
    			}

			my $res1 = $dialog1->Show;

    			#if ($res1) {
				#say "$res1";
        			#say $entryBits->get;
				#say $entryBitsTiming->get;
    			#}
		}
	}
############################## Vector Bits ########################################
	elsif ($signal_type =~ "Vector Bits"){

		my $btn1 = $mw->Button(
    			-text    => 'Timing Details',
    			-font    => ['fixed', 10],
    			-command => \&do_on_click2,
		);
		$btn1->place(-x => 110, -y => 245);

		sub do_on_click2 {
    			my $dialog2 = $mw->Dialog(
        			-title   => 'Timing Details',
        			-popover => $mw,
        			-buttons => ['Confirm', 'No'],
   			 );

			my @clock_timings2 = ('Timing based on clock ports');
			for my $clock_timing2 (@clock_timings2) {
   				$clk_rst2 = 0;
   				my $cb_clk2 = $dialog2->Checkbutton(
        				-text     => $clock_timing2,
        				-variable => \$clk_rst2,
					-command => \&do_on_click_clk2,
        				-font     => ['fixed', 10]
    					);
    				$cb_clk2->pack;
			}

			sub do_on_click_clk2 {
    				#print("Clicked\n");
        			#printf("%s\n",$clk_rst2); 
    				#print("----\n");
			}

			$option_menu_clk2 = 'Choose Clock Port';

			my $option_clk2 = $dialog2->Optionmenu(
    				-variable => \$option_menu_clk2,
    				-options  => \@clock_port,
			);
			$option_clk2->pack(); 


   		 	my $cycle_ports = do_on_clicked_S();

			###################### Time Metric #######################
			$dialog2->add("Label", -text => 'Time Metric :', -font => ['fixed', 10])->pack();

			$time_metric2 = 'ns';

			my $time_metric_entry2 = $dialog2->BrowseEntry(
    				-variable => \$time_metric2,
   				-state => 'readonly',
    				-command => \&time_metric_changed2,
    				-choices => [qw(ns us ms)],
			);

			$time_metric_entry2->pack();	

			sub time_metric_changed2 {
    				#say "Option menu set to: $time_metric2"
			}

			###################### Bits and Delay #######################
    			for (my $i = 0 ; $i <= $cycle_ports - 1 ; $i++) {
    				$dialog2->add("Label", -text => 'Bits : ', -font => ['fixed', 10])->pack();
    				$entry_Bit_Bits[$i] = $dialog2->add("Entry", -width => 64, -font => ['fixed', 10],)->pack();

				if ($i < $cycle_ports - 1) {
    					$dialog2->add("Label", -text => 'Delay Timing : ', -font => ['fixed', 10])->pack();
    					$entry_Bit_Delay[$i] = $dialog2->add("Entry", -width => 64, -font => ['fixed', 10],)->pack();
				}   
    			}		

    			my $res2 = $dialog2->Show;

   			#for (my $i = 0 ; $i <= $cycle_ports - 1 ; $i++) {
				#say $entry_Bit_Bits[$i]->get;

			#if ($i < $cycle_ports - 1) {
				#say $entry_Bit_Delay[$i]->get; }
    			#}
		}
	}
######################## Truth Table ########################################
	elsif ($signal_type =~ "Truth Table"){
		my $btn1 = $mw->Button(
    			-text    => 'Timing Details',
    			-font    => ['fixed', 10],
		);
		$btn1->place(-x => 110, -y => 245);
	}
}

my $btn1 = $mw->Button(
    -text    => 'Timing Details',
    -font    => ['fixed', 10],
);
$btn1->place(-x => 110, -y => 245);





######################## Reset #############################################

$mw->Label(-text => 'Reset/Enable', -font => ['bold',10])->place(-x => 310, -y => 120);
### No. of Cycle ###
$mw->Label(-text => 'No. Cycle :')->place(-x => 260, -y => 150);
my $entry_R = $mw->Entry(
    -font => ['fixed', 10],
    -width   => 3,
);
$entry_R->place(-x => 320, -y => 150);

my $btn_R = $mw->Button(
    -text    => 'Saved',
    -font    => ['fixed', 10],
    -command => \&do_on_clicked_R,
);
$btn_R->place(-x => 350, -y => 147);

sub do_on_clicked_R {

    #print("\nNo. Reset Cycle: ",$entry_R->get);

    return $entry_R->get;
}


my $btn4 = $mw->Button(
    -text    => 'Timing Details',
    -font    => ['fixed', 10],
    -command => \&do_on_click4,
);
$btn4->place(-x => 260, -y => 180);


my @entry_Reset_Bits;
my @entry_Reset_Delay;
my $time_metric3;
my $clk_rst3;
my $option_menu_clk3;

sub do_on_click4 {
	my $dialog3 = $mw->Dialog(
        -title   => 'Timing Details',
        -popover => $mw,
        -buttons => ['Confirm', 'No'],
    	);

	my @clock_timings3 = ('Timing based on clock ports');
	for my $clock_timing3 (@clock_timings3) {
   		$clk_rst3 = 0;
   		my $cb_clk3 = $dialog3->Checkbutton(
        		-text     => $clock_timing3,
        		-variable => \$clk_rst3,
			-command => \&do_on_click_clk3,
        		-font     => ['fixed', 10]
    			);
    		$cb_clk3->pack;
	}

	sub do_on_click_clk3 {
    		print("Clicked\n");
        	printf("%s\n",$clk_rst3); #{$clock_timing}
    		print("----\n");
	}

	$option_menu_clk3 = 'Choose Clock Port';

	my $option_clk3 = $dialog3->Optionmenu(
    		-variable => \$option_menu_clk3,
    		-options  => \@clock_port,
	);
	$option_clk3->pack(); 


	###################### Time Metric #######################
	$dialog3->add("Label", -text => 'Time Metric :', -font => ['fixed', 10])->pack();

	$time_metric3 = 'ns';

	my $time_metric_entry3 = $dialog3->BrowseEntry(
    		-variable => \$time_metric3,
   		-state => 'readonly',
    		-choices => [qw(ns us ms)],
		-command => \&time_metric_changed3,
	);
	$time_metric_entry3->pack();	

	sub time_metric_changed3 {
    		#say "Option menu set to: $time_metric3";
	}

	#$time_metric_entry3->configure(-state => 'disabled');

    my $reset_c = do_on_clicked_R();
	
    for (my $i = 0 ; $i <= $reset_c - 1 ; $i++) {
    	$dialog3->add("Label", -text => 'Clock On Timing : ', -font => ['fixed', 10])->pack();
    	$entry_Reset_Bits[$i] = $dialog3->add("Entry", -font => ['fixed', 10],)->pack();

    	$dialog3->add("Label", -text => 'Clock Off Timing : ', -font => ['fixed', 10])->pack();
    	$entry_Reset_Delay[$i] = $dialog3->add("Entry", -font => ['fixed', 10],)->pack();	
	  
    }

    my $res3 = $dialog3->Show;

   #for (my $i = 0 ; $i <= $reset_c - 1 ; $i++) {
	#say $entry_Reset_Bits[$i]->get;
	#say $entry_Reset_Delay[$i]->get; 
    #}
}





####################### Clock ##############################################

$mw->Label(-text => 'Clock', -font => ['bold',10])->place(-x => 540, -y => 120);
$mw->Label(-text => 'Clock Timing :')->place(-x => 500, -y => 150);
my $entry_C = $mw->Entry(
    -font => ['fixed', 10],
    -width   => 5,
);
$entry_C->place(-x => 595, -y => 150);

###################### Time Metric #######################
$mw->Label(-text => 'Time Metric :')->place(-x => 500, -y => 180);

my $time_metric4 = 'ns';

my $time_metric_entry4 = $mw->BrowseEntry(
    	-variable => \$time_metric4,
   	-state => 'readonly',
    	-command => \&time_metric_changed4,
    	-choices => [qw(ns us ms)],
	-width => 3,
);
$time_metric_entry4->place(-x => 570, -y => 180);	

sub time_metric_changed4 {
    	#say "Option menu set to: $time_metric4"
}

$mw->Label(-text => 'Duty Cycle in % :')->place(-x => 500, -y => 210);
my $entry_DC = $mw->Entry(
    -font => ['fixed', 10],
    -width   => 5,
);
$entry_DC->place(-x => 595, -y => 210);





####################### Saved ##############################################

$mw->Button(
    -text    => 'Saved',
    -font    => ['fixed', 10],
    -width   => 15,
    -command => \&saved,
)->place(-x => 500, -y => 240);




sub saved{

	if ($input_type =~ "Signal") {

		$signal_input[$no_signal_input] = $input_ports;
		print "\n\nInput Ports: $signal_input[$no_signal_input]";

		$signal_input_type[$no_signal_input] = $signal_type;

		my $cycle_ports = do_on_clicked_S();

		$signal_cycle[$no_signal_cycle] = $cycle_ports;
		#print "\nNo. Signal Cycle: $signal_cycle[$no_signal_cycle]";
		$no_signal_cycle = $no_signal_cycle + 1;

		if ($signal_type =~ "Single Bits") {

			$single_bits_time_metric[$no_signal_input] = $time_metric1;

			$single_bits_clk_port_yesno[$no_signal_input] = $clk_rst1;

			$single_bits_clk_port[$no_signal_input] = $option_menu_clk1;

   			for (my $i = 0 ; $i <= $cycle_ports - 1 ; $i++) {

				$signal_Bits[$no_signal_input][$i] = $entryBits[$i]->get;

				$signal_Bits_Timing[$no_signal_input][$i] = $entryBitsTiming[$i]->get;

				if ($single_bits_clk_port_yesno[$no_signal_input] == 0)
				{
					print "\nBits: $signal_Bits[$no_signal_input][$i] || Delay: $signal_Bits_Timing[$no_signal_input][$i] $single_bits_time_metric[$no_signal_input]";
				}
				else
				{
					print "\nBits: $signal_Bits[$no_signal_input][$i] || Delay: $signal_Bits_Timing[$no_signal_input][$i]*$single_bits_clk_port[$no_signal_input]\_PERIOD";
				}

				if ($i < $cycle_ports - 1) 
				{
					$signal_Timing[$no_signal_input][$i] = $entryTiming[$i]->get;

					if ($single_bits_clk_port_yesno[$no_signal_input] == 0)
					{
						print "\nDelay Timing: $signal_Timing[$no_signal_input][$i] $single_bits_time_metric[$no_signal_input]";
					}
					else
					{
						print "\nDelay Timing: $signal_Timing[$no_signal_input][$i]*$single_bits_clk_port[$no_signal_input]\_PERIOD";
					}
				}
			}
		}
		elsif ($signal_type =~ "Vector Bits") {

			$multiple_bits_time_metric[$no_signal_input] = $time_metric2;

			$multiple_bits_clk_port_yesno[$no_signal_input] = $clk_rst2;

			$multiple_bits_clk_port[$no_signal_input] = $option_menu_clk2;

   			for (my $i = 0 ; $i <= $cycle_ports - 1 ; $i++) {
				$signal_input_bits[$no_signal_input][$i] = $entry_Bit_Bits[$i]->get;
				print "\nBits: $signal_input_bits[$no_signal_input][$i]";

				if ($i < $cycle_ports - 1) {
					$signal_input_delay[$no_signal_input][$i] = $entry_Bit_Delay[$i]->get; 

					if ($multiple_bits_clk_port_yesno[$no_signal_input] == 0)
					{
						print "\nDelay: $signal_input_delay[$no_signal_input][$i] $multiple_bits_time_metric[$no_signal_input]";
					}
					else
					{
						print "\nDelay: $signal_input_delay[$no_signal_input][$i]*$multiple_bits_clk_port[$no_signal_input]\_PERIOD";
					}
				}
    			}
		}
		elsif ($signal_type =~ "Truth Table") {
			$signal_truthTable[$no_truth_table] = $signal_input[$no_signal_input];
			print "\nTruth Table: $signal_truthTable[$no_truth_table]";
			$no_truth_table = $no_truth_table + 1;
		}

		$no_signal_input = $no_signal_input + 1;
	}
	elsif ($input_type =~ "Reset") {

		$reset_port[$no_reset] = $input_ports;
		print "\nReset Port: $reset_port[$no_reset]";

		my $reset_c = do_on_clicked_R();
		$reset_cycle[$no_reset] = $reset_c;
		print "\nReset Cycle: $reset_cycle[$no_reset]";

		$reset_time_metric[$no_reset] = $time_metric3;
		print "\nTime Metric: $reset_time_metric[$no_reset]";

		$reset_clk_port_yesno[$no_reset] = $clk_rst3;

		$reset_clk_port[$no_reset] = $option_menu_clk3;

		print "\n Yes or No : $reset_clk_port_yesno[$no_reset]";

   		for (my $i = 0 ; $i <= $reset_c - 1 ; $i++) {
			$reset_on[$no_reset][$i] = $entry_Reset_Bits[$i]->get;
			$reset_off[$no_reset][$i] = $entry_Reset_Delay[$i]->get; 
			
			if ($reset_clk_port_yesno[$no_reset] == 0)
			{
				print "\nClock On: $reset_on[$no_reset][$i] || Clock Off: $reset_off[$no_reset][$i]";
			}
			else
			{
				print "\nClock On: $reset_on[$no_reset][$i]*$reset_clk_port[$no_reset]\_PERIOD || Clock Off: $reset_off[$no_reset][$i]*$reset_clk_port[$no_reset]\_PERIOD";
			}
    		}

		$no_reset = $no_reset + 1;
	}
	elsif ($input_type =~ "Clock") {
		$clock_port[$no_clock] = $input_ports;
		print "\nClock Port: $input_ports";

		$clock[$no_clock] = $entry_C->get;
		print "\nClock Cycle: $clock[$no_clock]";

		$clock_DC[$no_clock] = $entry_DC->get;
		print "\nClock Duty Cycle: $clock_DC[$no_clock]";

		$clock_time_metric[$no_clock] = $time_metric4;
		print "\nTime Metric: $clock_time_metric[$no_clock]";

		$no_clock = $no_clock + 1;
	}
}




############################## Truth Table Generation ##############################

$mw2->Button(-text => "Update", -command => \&update_table)
               ->pack(-side => 'right',-anchor => 's');

my $t;
my ($rows,$cols);
my $arrayVar = {};
my @combinations=();
my $count2 = 1;

sub update_table {
              
	$arrayVar = {};
	@combinations=();
	$count2 = 1;

	show_combinations($no_truth_table);

	($rows,$cols) = ($count2 , $no_truth_table);

	foreach my $col (0..($cols-1)){
    		$arrayVar->{"0,$col"} = "$signal_truthTable[$col]";

   		foreach my $row  (1..($rows-1)){

      			$arrayVar->{"$row,$col"} = "$combinations[$row][$col]";

   		}
	}
	
  	$t = $mw2->Scrolled('TableMatrix', -rows => $rows, -cols => $cols,
 	-width => 6, -height => 6,
 	-titlerows => 1,
 	-variable => $arrayVar,
	-selecttitles => 0,
 	-drawmode => 'slow',
 	-scrollbars=>'se'
 	);


	# Color definitions here:
	$t->tagConfigure('title', -bg => 'lightblue', -fg => 'black', -relief 
	=> 'sunken');
	$t->tagConfigure('dis', -state => 'disabled');
	$t->pack(-expand => 1);
	$t->focus;

	sub show_combinations { my($n,@prefix)=@_;                                      
 		if($n > 0) {                                                                  
    			show_combinations( $n-1, @prefix, 0);                                       
    			show_combinations( $n-1, @prefix, 1);                                       
  		} 
		else {                                                                      
    			#print " @prefix \n";    

    			for (my $j = 0 ; $j <= $no_truth_table - 1 ; $j++) {
				$combinations[$count2][$j] =  $prefix[$j];
			}
    		$count2 = $count2 + 1;                                                      
  		}                                                                             
	}
}


$mw2->Button(-text => "Saved", -command => \&save_table)
               ->pack(-side => 'right',-anchor => 's');


$mw2->Label(-text => 'Delay Timing :')->pack(-side => 'left',-anchor => 's');
my $entry_T = $mw2->Entry(
    -font => ['fixed', 10],
    -width   => 3,
);
$entry_T->pack(-side => 'left',-anchor => 's');


###################### Time Metric #######################
#$mw2->Label(-text => 'Time Metric :')->pack(-side => 'left',-anchor => 's');

my $time_metric5 = 'ns';

my $time_metric_entry5 = $mw2->BrowseEntry(
    	-variable => \$time_metric5,
   	-state => 'readonly',
    	-command => \&time_metric_changed5,
    	-choices => [qw(ns us ms)],
	-width => 3,
);

$time_metric_entry5->pack(-side => 'left',-anchor => 's');	

sub time_metric_changed5 {
    #say "Option menu set to: $time_metric5"
}

sub save_table {
	foreach my $row  (1..($rows-1)){
    		foreach my $col (0..($cols-1)){
			$input_truthTable[$row][$col] = $t->get("$row,$col");
			#print("\nTruth Table Value: ",$t->get("$row,$col"));
		}
	}
	#print ("\n Truth Table Delay Timing :",$entry_T->get);
	$input_delay = $entry_T->get;
	$input_delay_metric = $time_metric5;
}






############################## Generate Testbench ##############################

$mw->Button(
    -text    => 'Generate',
    -font    => ['fixed', 10],
    -width   => 15,
    -command => \&generate,
)->place(-x => 500, -y => 270);

sub generate{

open(my $inF, ">", $new_file_vhd);

# Print title
printf($inF "-------------------------------------------------------------------------------\n");
printf($inF "--                                                     Revision: 1.1 \n");
#printf($inF "--                                                     Date: %02d/%02d/%04d \n", $month+1, $day, $year+1900);
printf($inF "-------------------------------------------------------------------------------\n");
#printf($inF "--\t\t\t\t My Company Confidential Copyright © %04d My Company, Inc.\n", $year+1900);
printf($inF "--\n");
printf($inF "--   File name :  $file.vhd\n");
printf($inF "--   Title     :  Automatic HDL Testbench Generation\n");
printf($inF "--   Module    :  $file\n");
printf($inF "--   Author    :  $author\n");
printf($inF "--   Purpose   :  Year 4 FYP\n");
printf($inF "--\n");
#printf($inF "--   Roadmap   :\n");
printf($inF "-------------------------------------------------------------------------------\n");
#printf($inF "--   Modification History :\n");
#printf($inF "--\tDate\t\tAuthor\t\tRevision\tComments\n");
#printf($inF "--\t%02d/%02d/%04d\t$author\tRev A\t\tCreation\n", $month+1, $day, $year+1900);
#printf($inF "-------------------------------------------------------------------------------\n");
printf($inF "\n");

# Library 
printf($inF "Library IEEE;\n");
printf($inF "use IEEE.STD_LOGIC_1164.all;\n");
#printf($inF "use IEEE.std_logic_unsigned.all;\n");
#printf($inF "use IEEE.std_logic_arith.all;\n");
#printf($inF "use IEEE.Numeric_STD.all;\n");
#printf($inF "\n");
#printf($inF "library work;\n");
#my $new_text = join "_", $file, "pkgs.all";
#printf($inF "use work.$new_text;\n");
printf($inF "\n");
printf($inF "\n");

# Entity
printf($inF "-- Declare module entity. Declare module inputs, inouts, and outputs.\n");
printf($inF "entity $new_file is\n");
printf($inF "end $new_file;\n");
printf($inF "\n");

# Architecture
printf($inF "-- Begin module architecture/code.\n");
printf($inF "ARCHITECTURE behavior OF $new_file IS\n");
printf($inF "\n");

# Component
print ($inF "COMPONENT $file\n");	#print first line
print $inF " PORT(\n";		#print second line
my $out= join "\n\t", @ports;
print ($inF "$out\t\n\t\nEND COMPONENT;\n"); #print ports and last couple of lines
print ($inF "\n");

# UUT Port Signals
#printf($inF "-- UUT Port Signals.\n");
#printf($inF "$out;\n"); #print ports and last couple of lines
#printf($inF "\n");

printf($inF "-- Inputs & Outputs\n");
printf($inF "$out3\n");


printf($inF "\n-- Local parameter, wire, and register declarations go here.\n");
printf($inF "-- N/A\n");
printf($inF "-- general signals\n");
printf($inF "-- N/A\n");
printf($inF "\n");


printf($inF "-- *** Instantiate Constants ***\n");

if ($no_clock != 0)
{
# Clock
	for (my $i=1 ; $i <= $no_clock ; $i++)
	{
		printf($inF "constant $clock_port[$i-1]_PERIOD : time := $clock[$i-1] $clock_time_metric[$i-1];\n");
		printf($inF "\n");
	}
}

printf($inF "BEGIN\n");
printf($inF "\n");
printf($inF "-- Instantiate the UUT module.\n");
printf($inF "uut : $file\nport map (");       #print first line
printf($inF "\n\t$out2);\n\n");
printf($inF "\n");

# Generate Clock
if ($no_clock != 0)
{
printf($inF "-- Generate necessary clocks.\n");

	for (my $i=1 ; $i <= $no_clock ; $i++)
	{
		my $clock_time_current = $clock_DC[$i-1]/100;

		printf($inF "Clk_process$i: process\n");
		printf($inF "begin\n");
		printf($inF "\ttb_$clock_port[$i-1] <= '1';\n");
		printf($inF "\twait for $clock_port[$i-1]_PERIOD*$clock_time_current;\n");
		printf($inF "\ttb_$clock_port[$i-1] <= '0';\n");
		printf($inF "\twait for $clock_port[$i-1]_PERIOD*$clock_time_current;\n");
		printf($inF "end process;\n");
		printf($inF "\n");
	}
}

# Reset
if ($no_reset != 0)
{
printf($inF "-- Toggle the resets.\n");

	for (my $i=1 ; $i <= $no_reset ; $i++)
	{
		printf($inF "reset$i: process\n");
		printf($inF "begin\n");

		if ($reset_clk_port_yesno[$i-1] == 0)
		{
			for (my $j=0 ; $j <= $reset_cycle[$i-1] - 1 ; $j++)
			{
				printf($inF "\ttb_$reset_port[$i-1] <= '1';\n");
				printf($inF "\twait for $reset_on[$i-1][$j] $reset_time_metric[$i-1];\n");
				printf($inF "\ttb_$reset_port[$i-1] <= '0';\n");
				printf($inF "\twait for $reset_off[$i-1][$j] $reset_time_metric[$i-1];\n");
			}
			#printf($inF "\ttb_$reset_port[$i-1] <= '1';\n");
		}
		elsif ($reset_clk_port_yesno[$i-1] == 1)
		{
			for (my $j=0 ; $j <= $reset_cycle[$i-1] - 1 ; $j++)
			{
				printf($inF "\ttb_$reset_port[$i-1] <= '1';\n");
				printf($inF "\twait for $reset_on[$i-1][$j]*$reset_clk_port[$i-1]\_PERIOD;\n");
				printf($inF "\ttb_$reset_port[$i-1] <= '0';\n");
				printf($inF "\twait for $reset_off[$i-1][$j]*$reset_clk_port[$i-1]\_PERIOD;\n");
			}
			#printf($inF "\ttb_$reset_port[$i-1] <= '1';\n");
		}

		printf($inF "\twait;\n");
		printf($inF "end process;\n");
		printf($inF "\n");
	}
}


# Stimulus process

if ($no_signal_input != 0)
{
printf($inF "-- Insert Processes and code here.\n");
	for (my $i=1 ; $i <= $no_signal_input ; $i++)
	{
		my $signal_match = '0';
		for (my $k=0 ; $k <= $no_truth_table - 1 ; $k++)
		{
			if ($signal_input[$i-1] =~ $signal_truthTable[$k])
			{
				$signal_match = '1';
			}
		}
		
		if ($signal_match =~ '0')
		{
			printf($inF "-- Stimulus process$i\n");
			printf($inF "$signal_input[$i-1]: process\n");
			printf($inF "begin\n");

			if ($signal_input_type[$i-1] =~ "Single Bits")
			{
				for (my $j=0 ; $j <= $signal_cycle[$i-1] - 1 ; $j++)
				{
					my @arr=split (//, $signal_Bits[$i-1][$j]);
					foreach my $k (@arr){
						printf($inF "\ttb_$signal_input[$i-1] <= '$k';\n");

						if ($single_bits_clk_port_yesno[$i-1] == 0)
						{
							printf($inF "\twait for $signal_Bits_Timing[$i-1][$j] $single_bits_time_metric[$i-1];\n");
						}
						else
						{
							printf($inF "\twait for $signal_Bits_Timing[$i-1][$j]*$single_bits_clk_port[$i-1]\_PERIOD;\n");
						}

############################################ if last array, delete wait for last part ####################################################
					}

					if ($j < $signal_cycle[$i-1] - 1) {
						if ($single_bits_clk_port_yesno[$i-1] == 0)
						{
							printf($inF "\n\twait for $signal_Timing[$i-1][$j] $single_bits_time_metric[$i-1];\n\n");
						}
						else
						{
							printf($inF "\n\twait for $signal_Timing[$i-1][$j]*$single_bits_clk_port[$i-1]\_PERIOD;\n\n");
						}
					}
				}
			}
			elsif ($signal_input_type[$i-1] =~ "Vector Bits")
			{
				for (my $j=0 ; $j <= $signal_cycle[$i-1] - 1 ; $j++)
				{
	
					printf($inF "tb_$signal_input[$i-1] <= \"$signal_input_bits[$i-1][$j]\";\n");

					if ($j < $signal_cycle[$i-1] - 1) {
						if ($multiple_bits_clk_port_yesno[$i-1] == 0)
						{
							printf($inF "wait for $signal_input_delay[$i-1][$j] $multiple_bits_time_metric[$i-1];\n");
						}
						else
						{
							printf($inF "wait for $signal_input_delay[$i-1][$j]*$multiple_bits_clk_port[$i-1]\_PERIOD;\n");
						}
					}
				}
			}

			printf($inF "wait;\n");
			printf($inF "end process;\n");
			printf($inF "\n");
		}
	}
	
	if ($no_truth_table > 0)
	{
		printf($inF "-- Stimulus process\n");
		printf($inF "stim_proc: process\n");
		printf($inF "begin\n");

		for (my $i=1 ; $i <= $rows - 1 ; $i++)
		{
			if ($i > 0)
			{
				printf($inF "wait for $input_delay $input_delay_metric;\n\n");
			}

			for (my $j=0 ; $j <= $no_truth_table - 1 ; $j++)
			{
				printf($inF "tb_$signal_truthTable[$j] <= \'$input_truthTable[$i][$j]\';\n");
			}
		}
		printf($inF "wait;\n");
		printf($inF "end process;\n");
		printf($inF "\n");
	}

}

printf($inF "END behavior; -- architecture\n");
printf($inF "\n");
printf($inF "\n");

#my $new_text2 = join "_", $new_file, "cfg";
#printf($inF "configuration $new_text2 of $new_file is\n");
#printf($inF "for behavior\n");
#printf($inF "end for;\n");
#printf($inF "end $new_text2;\n");

close(inF); 

print("\nThe script has finished successfully! You can now use the file $new_file_vhd.\n\n");


##################### Reset all the variable ################################
$no_signal_input = 0;
@signal_input = ();
$no_signal_cycle = 0;
@signal_cycle = ();
@signal_input_type = ();
@signal_Bits_Timing = ();
@signal_Timing = ();
@signal_input_bits = ();
@signal_input_delay = ();
$no_truth_table = 0;
@signal_truthTable = ();

@single_bits_clk_port_yesno = ();
@single_bits_clk_port = ();
@multiple_bits_clk_port_yesno = ();
@multiple_bits_clk_port = ();
@multiple_bits_time_metric = ();
@single_bits_time_metric = ();

$no_reset = 0;
@reset_port = ();
@reset_cycle = ();
@reset_on = ();
@reset_off = ();
@reset_time_metric = ();
@reset_clk_port_yesno = ();
@reset_clk_port = ();

$no_clock = 0;
@clock = ();
@clock_DC = ();
@clock_port = ();
@clock_time_metric = ();

@input_truthTable = ();
$input_delay = 0;
$input_delay_metric = 0;

$t->destroy;

}

MainLoop();

tie *STDOUT, ref $text, $text;

#------------------------------------------------------------------------------ 
# Generic Error and Exit routine 
#------------------------------------------------------------------------------

sub dienice {
	my($errmsg) = @_;
	print"$errmsg\n";
	exit;
}
 