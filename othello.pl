use IO::Socket::INET;
use strict;
our @array = qw /0 0 0 0 0 0 0 0  0 0 0 0 0 0 0 0  0 0 0 0 0 0 0 0  0 0 0 1 2 0 0 0  0 0 0 2 1 0 0 0  0 0 0 0 0 0 0 0  0 0 0 0 0 0 0 0  0 0 0 0 0 0 0 0/;
our @data;
our $turn_count = 0;

my $socket = new IO::Socket::INET (
	#PeerHost => '127.0.0.1',
	PeerHost => '192.168.0.100',
	PeerPort => '8472',
	#PeerPort => '5000',
	Proto => 'tcp',
);
die "cannot connect to the server $!\n" unless $socket;
print set_board(@array);
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
		push @data,"nope";
		push @data,(($column*8) + $row);
		if ($data[0] == 1) { $array[$data[-1]] = 4}
		elsif ($data[0] == 2) { $array[$data[-1]] = 3}
	}

	my $change = $hash{'changed_points'};
	$change =~ s/\[\[/\[/g;
	$change =~ s/\]\]/\]/g;
	$change =~ s/^\[|\]$//g;
	
	foreach(split(/\],\[/,$change)){
			my ($column,$row) = split(/,/,$_);
			my $change_index = ($column *8 + $row);
			if   ($array[$change_index] == 1) { $array[$change_index] = 2}
			elsif($array[$change_index] == 2) { $array[$change_index] = 1}
		}


	
}

sub gameover()
{
	my (%hash) = @_;
	my $win = $hash{'result'};
	print "GAMEOVER YOURE WINNER ! \n" if ($win); 
	print "GAMEOVER YOURE LOOSER ! \n" unless ($win); 
	print "data : @data\n";
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
		   if ($data[0] == 1) { $array[$data[-1]] = 4}
		elsif ($data[0] == 2) { $array[$data[-1]] = 3}
	}
	my $change = $hash{'changed_points'};
	$change =~ s/\[\[/\[/g;
	$change =~ s/\]\]/\]/g;
	$change =~ s/^\[|\]$//g;
	
	foreach(split(/\],\[/,$change)){
			my ($column,$row) = split(/,/,$_);
			my $change_index = ($column *8 + $row);
			if   ($array[$change_index] == 1) { $array[$change_index] = 2}
			elsif($array[$change_index] == 2) { $array[$change_index] = 1}
		}


	my $point = $hash{'available_points'};
	$point =~ s/\[\[/\[/g;
	$point =~ s/\]\]/\]/g;
	$point =~ s/^\[|\]$//g;

	foreach(split(/\],\[/,$point)){
		my ($column,$row) = split(/,/,$_);
		push @ret,(($column*8) + ($row));
	}
	my $put = &onetotwo($ret[0]);
	push @data,$ret[0];
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
	#print "json : $json\n";
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
	#	@array = qw /2 2 2 2 2 2 2 2  1 1 1 1 1 1 1 1  1 1 1 1 1 1 1 1  0 0 0 1 2 0 0 0  0 0 0 2 1 0 0 0  0 0 0 2 1 2 1 2  0 0 0 0 0 0 0 0  0 0 0 0 2 1 1 1/;

	while($index < 64){
		for my $ttt(1 .. 3){
			$print .=  "\t\t\t\t\t\t|";
			for(1 .. 8){
				if($array[$index + $_ - 1] == 0) {$print .= $none;}
				elsif($array[$index + $_ - 1] == 1) {$print .=  $white}
				elsif($array[$index + $_ - 1] == 2) {$print .=  $black}
				elsif($array[$index + $_ - 1] == 3) {$print .=  $white_focus}
				elsif($array[$index + $_ - 1] == 4) {$print .=  $black_focus}
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


print &set_board(1);
