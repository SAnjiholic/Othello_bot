use IO::Socket::INET;
use strict;
our @array = qw /0 0 0 0 0 0 0 0  0 0 0 0 0 0 0 0  0 0 0 0 0 0 0 0  0 0 0 2 1 0 0 0  0 0 0 1 2 0 0 0  0 0 0 0 0 0 0 0  0 0 0 0 0 0 0 0  0 0 0 0 0 0 0 0/;
our @data;
our $turn_count = 0;

chomp (my $default_f = `pwd`);

my $socket = new IO::Socket::INET (
	PeerHost => '127.0.0.1',
	#PeerHost => '192.168.1.114',
	PeerPort => '8472',
	#PeerPort => "$ARGV[0]",
	#PeerPort => '5000',
	Proto => 'tcp',
);
die "cannot connect to the server $!\n" unless $socket;

#print set_board(@array);

my $response = "";

while(1){
	$socket->recv($response, 1024);
	if($response){
		my @test = split(//,$response);
		my ($length,$data) = unpack("N A*",$response);
		my %json = json_decode($data,$length);
		my $flag = $json{'type'};
		if ($flag == 0){print "Ready\n"}	
		elsif($flag == 1) { &start(%json)}
		elsif($flag == 2) { $socket->send(&my_turn(%json))}
		elsif($flag == 5) { &nopoint(%json)}#	push @data,"nope";}
		elsif($flag == 6) { &gameover(%json)}
		elsif($flag == 7) { print "ERROR\n"}
	}
}

$socket->close();

sub write()
{
	my (@change_index) = @_;
	foreach (@change_index){
		if($array[$_] == 1 ) { $array[$_] = 2}
		elsif($array[$_] == 2 ) { $array[$_] = 1}
	}
}

sub start()
{
	my (%hash) = @_;
	$data[0] = $hash{'color'};
	print "Game Start\n my color : $data[0]\n";
}

sub nopoint(){
	my (%hash) = @_;
	my $opponent_put = $hash{'opponent_put'};
	unless ($opponent_put eq "null"){
		$opponent_put =~ s/\[|\]//g;
		my ($column,$row) = split(/,/,$opponent_put);
		#		push @data,"nope";
		push @data,(($column*8) + $row);
		if ($data[0] == 1) { $array[$data[-1]] = 4}
		elsif ($data[0] == 2) { $array[$data[-1]] = 3}
	}
	&processing($data[-1],1);
}

sub gameover()
{
	my (%hash) = @_;
	my $win = $hash{'result'};
	print &win_ascii if ($win); 
	unless($win){
		my $last_put = $hash{'opponent_put'};
		unless ($last_put eq "null"){
			$last_put =~ s/\[|\]//g;
			my ($column,$row) = split(/,/,$last_put);
			push @data,(($column*8) + $row);
			if ($data[0] == 1) { $array[$data[-1]] = 2}
			elsif ($data[0] == 2) { $array[$data[-1]] = 1}
			&processing($data[-1],1);	
			print set_board(@array);
			print &lost_ascii unless ($win);
		}
	}
	$socket->close();
	exit();
}

sub my_turn()
{
	$turn_count++;
	my (%hash) = @_;
	my @ret;
	my $opponent_put = $hash{'opponent_put'};

	unless ($opponent_put eq "null"){
		$opponent_put =~ s/\[|\]//g;
		my ($column,$row) = split(/,/,$opponent_put);
		push @data,(($column*8) + $row);
		if ($data[0] == 1) { $array[$data[-1]] = 2}
		elsif ($data[0] == 2) { $array[$data[-1]] = 1}
		#		print set_board(@array);
		&processing($data[-1],1);
	}

	my $point = $hash{'available_points'};
	$point =~ s/\[\[/\[/g;
	$point =~ s/\]\]/\]/g;
	$point =~ s/^\[|\]$//g;

	foreach(split(/\],\[/,$point)){
		my ($column,$row) = split(/,/,$_);
		push @ret,(($column*8) + ($row));
	}
	my $put;
	foreach (@ret){
		if ( $_ == 0 || $_ == 3 || $_ == 5 || $_ == 7 || $_ == 16 || $_ == 24 ||$_ ==  40 ||$_ ==  56 ||$_ ==  58 ||$_ ==  60 ||$_ ==  63 || $_ == 47 ||$_ == 31 || $_ == 15){
			$put = &onetotwo($_);
			push @data,$_;
			print set_board;
		}
		else {
			my $rand = int(rand($#ret +1 ));
			$put = &onetotwo($ret[$rand]);
			push @data,$ret[$rand];
		}
	}
	#	my $rand = int(rand($#ret +1 ));
	# my $put = &onetotwo($ret[$rand]);
	# push @data,$ret[$rand];
	print set_board(@array);
	&processing($data[-1], 0 );
	$array[$data[-1]] = $data[0]+2;
	print set_board(@array);
	my $json = '{"type":0,"point":'."$put}";
	my $length  = length($json);
	my $header = pack("N",$length);
	return $header.$json;
}

sub twotoone()
{

}

sub onetotwo()
{
	my $a = shift;
	return  "[".int($a/8).",".($a%8)."]";
}

sub json_encode()
{
	my (%hash) = @_;
	my $json = "{";
	foreach (keys(%hash)){
		$json .= "'";
		$json .= $_;
		$json .= "'";
		$json .= ":";
		$json .= $hash{"$_"};
		$json .= ",";
	}
	$json =~ s/,$//g;
	$json .= "}";
	return $json;
}

sub json_decode()
{
	my $json= shift;
	my $length = shift;
	$json = unpack("A$length") if length($json) != $length;
	$json =~ s/: /:/g;
	$json =~ s/,( )+"/,"/g;
	$json =~ s/, /,/g;
	$json =~ s/^{|}$//g;
	$json =~ s/^"//g;

	my @array = split(/,"/ , $json);
	my %hash;
	foreach(@array){
		my @tmp = split(/":/,$_);
		$hash{$tmp[0]} = $tmp[1];
	}

	return %hash
}
sub set_board()
{
	system('clear');
	my $black = " ■■■■■■ ";
	my $white = " □□□□□□ ";
	my $black_focus = " ★★★★★★ ";
	my $white_focus = " ☆☆☆☆☆☆ ";
	my $none =  "        ";
	my $ascii ="\n\n";
	$ascii .="	███████╗ █████╗ ███╗   ██╗     ██╗██╗██╗  ██╗ ██████╗ ██╗     ██╗ ██████╗               ██████╗ ████████╗██╗  ██╗███████╗██╗     ██╗      ██████╗     ██╗\n";
	$ascii .="	██╔════╝██╔══██╗████╗  ██║     ██║██║██║  ██║██╔═══██╗██║     ██║██╔════╝              ██╔═══██╗╚══██╔══╝██║  ██║██╔════╝██║     ██║     ██╔═══██╗    ██║\n";
	$ascii .="	███████╗███████║██╔██╗ ██║     ██║██║███████║██║   ██║██║     ██║██║         █████╗    ██║   ██║   ██║   ███████║█████╗  ██║     ██║     ██║   ██║    ██║\n";
	$ascii .="	╚════██║██╔══██║██║╚██╗██║██   ██║██║██╔══██║██║   ██║██║     ██║██║         ╚════╝    ██║   ██║   ██║   ██╔══██║██╔══╝  ██║     ██║     ██║   ██║    ╚═╝\n";
	$ascii .="	███████║██║  ██║██║ ╚████║╚█████╔╝██║██║  ██║╚██████╔╝███████╗██║╚██████╗              ╚██████╔╝   ██║   ██║  ██║███████╗███████╗███████╗╚██████╔╝    ██╗\n";
	$ascii .="	╚══════╝╚═╝  ╚═╝╚═╝  ╚═══╝ ╚════╝ ╚═╝╚═╝  ╚═╝ ╚═════╝ ╚══════╝╚═╝ ╚═════╝               ╚═════╝    ╚═╝   ╚═╝  ╚═╝╚══════╝╚══════╝╚══════╝ ╚═════╝     ╚═╝\n";


	my $print = $ascii . "\n\n\n\n\t\t\t\t\t\t ________ ________ ________ ________ ________ ________ ________ ________\n";
	my $line =  "\t\t\t\t\t\t|________|________|________|________|________|________|________|________|\n";
	my $index = 0;

	while($index < 64){
		for my $ttt(1 .. 3){
			$print .=  "\t\t\t\t\t\t|";
			for(1 .. 8){
				if($array[$index + $_ - 1] == 0) {$print .= $none;}
				elsif($array[$index + $_ - 1] == 1) {$print .=  $black}
				elsif($array[$index + $_ - 1] == 2) {$print .=  $white}
				elsif($array[$index + $_ - 1] == 3) {$print .=  $black_focus}
				elsif($array[$index + $_ - 1] == 4) {$print .=  $white_focus}

				$print .= "|";
			}
			$print .= "\n";
		}
		$print .=  $line;
		$index += 8;
	}
	my $reset_index = 0;
	foreach(@array){
		$array[$reset_index] = ($_ - 2) if ($_ > 2);
		$reset_index++;
	}
	return $print;
}

sub win_ascii()
{
	my $ascii = "\n\n\n";
	$ascii .= "\t\t\t\t\t\t\t██╗   ██╗ ██████╗ ██╗   ██╗    ██╗    ██╗██╗███╗   ██╗██╗\n";
	$ascii .= "\t\t\t\t\t\t\t╚██╗ ██╔╝██╔═══██╗██║   ██║    ██║    ██║██║████╗  ██║██║\n";
	$ascii .= "\t\t\t\t\t\t\t ╚████╔╝ ██║   ██║██║   ██║    ██║ █╗ ██║██║██╔██╗ ██║██║\n";
	$ascii .= "\t\t\t\t\t\t\t  ╚██╔╝  ██║   ██║██║   ██║    ██║███╗██║██║██║╚██╗██║╚═╝\n";
	$ascii .= "\t\t\t\t\t\t\t   ██║   ╚██████╔╝╚██████╔╝    ╚███╔███╔╝██║██║ ╚████║██╗\n";
	$ascii .= "\t\t\t\t\t\t\t   ╚═╝    ╚═════╝  ╚═════╝      ╚══╝╚══╝ ╚═╝╚═╝  ╚═══╝╚═╝\n";
}

sub lost_ascii()
{
	my $ascii = "\n\n\n";
	$ascii .= "\t\t\t\t\t\t █╗   ██╗ ██████╗ ██╗   ██╗    ██╗      ██████╗ ███████╗████████╗            ██╗\n";
	$ascii .= "\t\t\t\t\t\t╚██╗ ██╔╝██╔═══██╗██║   ██║    ██║     ██╔═══██╗██╔════╝╚══██╔══╝    ██╗    ██╔╝\n";
	$ascii .= "\t\t\t\t\t\t ╚████╔╝ ██║   ██║██║   ██║    ██║     ██║   ██║███████╗   ██║       ╚═╝    ██║ \n";
	$ascii .= "\t\t\t\t\t\t  ╚██╔╝  ██║   ██║██║   ██║    ██║     ██║   ██║╚════██║   ██║       ██╗    ██║ \n";
	$ascii .= "\t\t\t\t\t\t   ██║   ╚██████╔╝╚██████╔╝    ███████╗╚██████╔╝███████║   ██║       ╚═╝    ╚██╗\n";
	$ascii .= "\t\t\t\t\t\t   ╚═╝    ╚═════╝  ╚═════╝     ╚══════╝ ╚═════╝ ╚══════╝   ╚═╝               ╚═╝\n";
}

sub processing()
{
	my $base_color = $data[0];
	my $base = shift;
	my $flag = shift;
	if ($flag != 0) {if   ($base_color == 1) {$base_color = 2}  
					 elsif($base_color == 2) {$base_color = 1}
				 }
	my $column = int($base / 8);
	my $row = $base % 8 ;
	my @change_ret ;
	my $a = $base - 9 if ($column > 1 || $row > 1);
	my $b = $base - 8 if ($column > 1);
	my $c = $base - 7 if ($column > 1 || $row < 6);
	my $d = $base - 1 if ($row > 1);
	my $e = $base + 1 if ($row < 6);
	my $f = $base + 7 if ($column < 6 || $row > 1); 
	my $g = $base + 8 if ($column < 6 );
	my $h = $base + 9 if ($column < 6 || $row < 6);

	if ($a) { 
		my @tmp;
		my $flag = 0;
		while($a > -1 && $a < 64) {
			last if ($array[$a] == 0 || int($a/8) == $column);
			if ($array[$a] == $base_color) { $flag = 1; last;} 
			push @tmp,$a;
			$a -= 9;
		}
		if ($flag) { foreach(@tmp){push @change_ret,$_;}}
	}

	if ($b) { 
		my @tmp;
		my $flag = 0;
		while($b > -1 && $b < 64) {
			last if ($array[$b] == 0);
			if ($array[$b] == $base_color) { $flag = 1; last;} 
			push @tmp,$b;
			$b -= 8;
		}
		if ($flag) { foreach(@tmp){push @change_ret,$_;}}
	}

	if ($c) { 
		my @tmp;
		my $flag = 0;
		my $line = int($c/8);
		while($c > -1 && $c < 64) {
			last if ($array[$c] == 0 || int($c/8) == $column);
			if ($array[$c] == $base_color) { $flag = 1; last;} 
			push @tmp,$c;
			$c -= 7;
		}
		if ($flag) { foreach(@tmp){push @change_ret,$_;}}
	}

	if ($d) { 
		my @tmp;
		my $flag = 0;
		my $line = int ($d /8);
		while($d > -1 && $d < 64 && $line == int ($d/8)) {
			last if ($array[$d] == 0);
			if ($array[$d] == $base_color) { $flag = 1; last;} 
			push @tmp,$d;
			$d -= 1;
		}
		if ($flag) { foreach(@tmp){push @change_ret,$_;}}
	}


	if ($e) { 
		my @tmp;
		my $flag = 0;
		my $line = int ($e/8);
		while($e > -1 && $e < 64 && $line == int($e/8)) {
			last if ($array[$e] == 0);
			if ($array[$e] == $base_color) { $flag = 1; last;} 
			push @tmp,$e;
			$e += 1;
		}
		if ($flag) { foreach(@tmp){push @change_ret,$_;}}
	}

	if ($f) { 
		my @tmp;
		my $flag = 0;
		while($f > -1 && $f < 64) {
			last if ($array[$f] == 0 || int($f/8) == $column);
			if ($array[$f] == $base_color) { $flag = 1; last;} 
			push @tmp,$f;
			$f += 7;
		}
		if ($flag) { foreach(@tmp){push @change_ret,$_;}}
	}

	if ($g) { 
		my @tmp;
		my $flag = 0;
		while($g > -1 && $g < 64) {
			last if ($array[$g] == 0);
			push @tmp,$g;
			$g += 8;
			if ($array[$g] == $base_color) { $flag = 1; last;} 
		}
		if ($flag) { foreach(@tmp){push @change_ret,$_;}}
	}

	if ($h) { 
		my @tmp;
		my $flag = 0;
		while($h > -1 && $h < 64) {
			last if ($array[$h] == 0 || int($h/8) == $column);
			if ($array[$h] == $base_color) { $flag = 1; last;} 
			push @tmp,$h;
			$h += 9;
		}
		if ($flag) { foreach(@tmp){push @change_ret,$_;}}
	}
	&write(@change_ret);
}

