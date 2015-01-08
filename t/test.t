#!/usr/bin/perl
# test.t - intended for testing the fastAPD perl module
# Author - Joseph D. Baugher, PhD
# Copyright (c) 2014 Joseph D. Baugher (<jbaughe2@jhmi.edu>). All rights reserved.
#
# This module is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself. See L<perlartistic>.
#  
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

use warnings;
use strict;
use Test::More tests => 44;
use lib '../lib';
use Bio::fastAPD;
 
no warnings qw{qw uninitialized}; 

my $test_dir = "t//test_data//"; 
 
my $fastAPD_obj = Bio::fastAPD->new();

ok( defined $fastAPD_obj, 'new() returned an object' );
ok($fastAPD_obj->isa('Bio::fastAPD'), 'it is a Bio::fastAPD object' ); 

my $file_name = $test_dir . "dna_equal_length.fasta";
ok(-r $file_name,'can read files');

my $sequences_ref = create_seq_array($file_name);
ok(@$sequences_ref,'sequence array created');

ok($fastAPD_obj->initialize(seq_array_ref => $sequences_ref,
                            alphabet      => 'dna'), 
    "initialize dna object");
    
my $n_reads = $fastAPD_obj->n_reads();
is($n_reads, 20, "correct number of reads");        
                                                  
my $n_valid_pos = $fastAPD_obj->n_valid_positions();
is($n_valid_pos, 300, 'correct number of valid positions');
my $valid_pos_ref = $fastAPD_obj->valid_positions();
is_deeply($valid_pos_ref, [(0..299)], 'correct sequence of valid positions');
    
my $fastapd = $fastAPD_obj->calculate_diversity(method  => 'fast_apd',
                                                compare => 'gap_base');
                                                
my $apdbypos = $fastAPD_obj->calculate_diversity(method  => 'apd_by_pos',
                                                 compare => 'gap_base');
                                            
is(round($fastapd), round(0.059859649122807), 'apd method correct');                                                              
is(round($fastapd), round($apdbypos), 'apd methods match');
 
my $fastapd_se = $fastAPD_obj->calculate_apd_std_err(method  => 'fast_apd',
                                                     compare => 'gap_base');
                                                
my $apdbypos_se = $fastAPD_obj->calculate_apd_std_err(method  => 'apd_by_pos',
                                                      compare => 'gap_base');
                                            
is(round($fastapd_se), round($apdbypos_se), 'standard error results match');
 
 
################# Masking
 
 my $fastAPD_obj2 = Bio::fastAPD->new();

# Create a binary mask instructing the module to ignore the first and last positions
my $mask = join("", 0, 1 x (length($$sequences_ref[0])-2), 0);    

$fastAPD_obj2->initialize(seq_array_ref => $sequences_ref,
                          alphabet      => 'dna',
                          mask          => $mask);
                         
$fastapd = $fastAPD_obj2->calculate_diversity(method  => 'fast_apd',
                                              compare => 'gap_base');

$fastapd_se = $fastAPD_obj2->calculate_apd_std_err(method  => 'fast_apd',
                                                   compare => 'gap_base');

$n_valid_pos = $fastAPD_obj2->n_valid_positions();
is($n_valid_pos, 298, 'number of masked positions correct');
$valid_pos_ref = $fastAPD_obj2->valid_positions();
is_deeply($valid_pos_ref, [(1..298)], 'masking');
                                                                                                                

################# Symbol frequencies

my $fastAPD_obj3 = Bio::fastAPD->new();
$sequences_ref = create_seq_array($test_dir . "freq.fasta");
$fastAPD_obj3->initialize(seq_array_ref => $sequences_ref,
                          alphabet      => 'dna');

my $freq_array_ref = $fastAPD_obj3->freqs();
my $freq_string =  "@$freq_array_ref";
my $expected_freqs =  join(" ", join("\t",qw/# - A C G N T/),
                                join("\t",qw/0 0 4 0 0 0 0/),
                                join("\t",qw/0 0 0 4 0 0 0/),
                                join("\t",qw/0 2 0 0 0 0 2/),
                                join("\t",qw/0 0 0 0 4 0 0/),
                                join("\t",qw/0 0 2 0 0 2 0/),
                                join("\t",qw/0 0 0 4 0 0 0/),
                                join("\t",qw/0 0 0 0 0 0 4/),
                                join("\t",qw/1 0 0 0 3 0 0/),
                                join("\t",qw/2 0 2 0 0 0 0/),
                                join("\t",qw/2 0 0 2 0 0 0/));
is($freq_string, $expected_freqs, 'Symbol frequencies test');


################# Gap threshold

my $gap_thresh  = 0.4; # Ignore positions with > 40% gaps
$fastAPD_obj3->gap_threshold($gap_thresh);
is($fastAPD_obj3->gap_threshold(), $gap_thresh, 'set and get gap threshold');
$fastapd = $fastAPD_obj3->calculate_diversity(method  => 'fast_apd',
                                               compare => 'gap_base');
$fastapd_se = $fastAPD_obj3->calculate_apd_std_err(method  => 'fast_apd',
                                                   compare => 'gap_base');
$valid_pos_ref = $fastAPD_obj3->valid_positions();
is_deeply($valid_pos_ref, [(0,1,3..9)], 'sequence of valid positions - gap threshold');


################# Null threshold    

my $null_thresh  = 0.4; # Ignore positions with > 40% nulls
$fastAPD_obj3->null_threshold($null_thresh);
is($fastAPD_obj3->null_threshold(), $null_thresh, 'set and get null threshold');
$fastapd = $fastAPD_obj3->calculate_diversity(method  => 'fast_apd',
                                               compare => 'gap_base');
$fastapd_se = $fastAPD_obj3->calculate_apd_std_err(method  => 'fast_apd',
                                                   compare => 'gap_base');
$valid_pos_ref = $fastAPD_obj3->valid_positions();
is_deeply($valid_pos_ref, [(0,1,3,5..9)], 'sequence of valid positions - null threshold');


################# Ragged end threshold    

my $end_thresh  = 0.4; # Ignore positions with > 40% ends
$fastAPD_obj3->end_threshold($end_thresh);
is($fastAPD_obj3->end_threshold(), $end_thresh, 'set and get end threshold');
$fastapd = $fastAPD_obj3->calculate_diversity(method  => 'fast_apd',
                                               compare => 'gap_base');
$fastapd_se = $fastAPD_obj3->calculate_apd_std_err(method  => 'fast_apd',
                                                   compare => 'gap_base');
$valid_pos_ref = $fastAPD_obj3->valid_positions();
is_deeply($valid_pos_ref, [(0,1,3,5..7)], 'sequence of valid positions - end threshold');


################# Consensus sequence 
                                                      
my $observed_consensus = $fastAPD_obj->consensus_alignment();
is($observed_consensus, 'ACTGACTGAC', 'consensus sequence');


################# Gap comparison options

my $fastAPD_obj4 = Bio::fastAPD->new();
$sequences_ref = create_seq_array($test_dir . "gap_test.fasta");

$fastAPD_obj4->initialize(seq_array_ref => $sequences_ref,
                          alphabet      => 'dna');
# gap_base
my $apd_g_b = $fastAPD_obj4->calculate_diversity(method  => 'fast_apd',
                                                 compare => 'gap_base');
is(round($apd_g_b), 0.434783, "fast_apd gap_base comparison mode");    

my $se_g_b = $fastAPD_obj4->calculate_apd_std_err(method  => 'fast_apd',
                                                  compare => 'base_base');
is(round($se_g_b), 0.191338, 'standard error - fast_apd gap_base comparison mode');    

$apd_g_b = $fastAPD_obj4->calculate_diversity(method  => 'apd_by_pos',
                                              compare => 'gap_base');
is($apd_g_b, 0.45, "apd_by_pos gap_base comparison mode");    

$se_g_b = $fastAPD_obj4->calculate_apd_std_err(method  => 'fast_apd',
                                               compare => 'base_base');
is(round($se_g_b), 0.191338, 'standard error - apd_by_pos gap_base comparison mode');    

# base_base
my $apd_b_b = $fastAPD_obj4->calculate_diversity(method  => 'fast_apd',
                                                 compare => 'base_base');
is($apd_b_b, 0.1875, 'fast_apd base_base comparison mode');    

my $se_b_b = $fastAPD_obj4->calculate_apd_std_err(method  => 'fast_apd',
                                                  compare => 'base_base');
is(round($se_b_b), 0.191338, 'standard error - fast_apd base_base comparison mode');    
                                                                
$apd_b_b = $fastAPD_obj4->calculate_diversity(method  => 'apd_by_pos',
                                              compare => 'base_base');
is($apd_b_b, 0.125, 'apd_by_pos base_base comparison mode');                                                                    

$se_b_b = $fastAPD_obj4->calculate_apd_std_err(method  => 'fast_apd',
                                               compare => 'base_base');
is(round($se_b_b), 0.191338, 'standard error - apd_by_pos base_base comparison mode');    

# gap_gap                                    
my $apd_g_g = $fastAPD_obj4->calculate_diversity(method  => 'fast_apd',
                                                 compare => 'gap_gap');
is(round($apd_g_g), 0.416667, 'fast_apd gap_gap comparison mode');    
    
my $se_g_g = $fastAPD_obj4->calculate_apd_std_err(method  => 'fast_apd',
                                                  compare => 'base_base');
is(round($se_g_g), 0.191338, 'standard error - fast_apd gap_gap comparison mode');    
                                                                
$apd_g_g = $fastAPD_obj4->calculate_diversity(method  => 'apd_by_pos',
                                              compare => 'gap_gap');
is(round($apd_g_g), 0.416667, 'apd_by_pos gap_gap comparison mode');

$se_g_g = $fastAPD_obj4->calculate_apd_std_err(method  => 'fast_apd',
                                               compare => 'base_base');
is(round($se_g_g), 0.191338, 'standard error - apd_by_pos gap_gap comparison mode');        

# complete_del                                                                                                                                                    
my $apd_del = $fastAPD_obj4->calculate_diversity(method  => 'fast_apd',
                                                 compare => 'complete_del');
is($apd_del, 0.25, 'fast_apd complete_del comparison mode');

my $se_del = $fastAPD_obj4->calculate_apd_std_err(method  => 'fast_apd',
                                                  compare => 'base_base');
is($se_del, 0.25, 'standard error - fast_apd complete_del comparison mode');    

$apd_del = $fastAPD_obj4->calculate_diversity(method  => 'apd_by_pos',
                                              compare => 'complete_del');
is($apd_del, 0.25, 'apd_by_pos complete_del comparison mode');
    
$se_del = $fastAPD_obj4->calculate_apd_std_err(method  => 'fast_apd',
                                               compare => 'base_base');
is($se_del, 0.25, 'standard error - apd_by_pos complete_del comparison mode');        
    
$n_valid_pos = $fastAPD_obj4->n_valid_positions();
is($n_valid_pos, 2, 'number of masked positions');
    

################# RNA and protein functionality

my @testing_array = (['rna.fasta', 'rna', 0.434783, 0.154562],
                     ['protein.fasta', 'protein', 0.523322, 0.047011]);
                    
foreach my $test_scenario (@testing_array) {
    $file_name       = $test_dir . $$test_scenario[0];
    my $alphabet     = $$test_scenario[1];
    my $expected_apd = $$test_scenario[2];
    my $expected_se  = $$test_scenario[3];
    
    my $fastAPD_obj = Bio::fastAPD->new();

    my $sequences_ref = create_seq_array($file_name);        
    ok($fastAPD_obj->initialize(seq_array_ref => $sequences_ref,
                                alphabet      => $alphabet), 
        "initialize $alphabet object");
    
    $fastapd = $fastAPD_obj->calculate_diversity(method  => 'fast_apd',
                                                 compare => 'gap_base');
    is(round($fastapd), $expected_apd, "check $alphabet fast_apd");    
    
    $fastapd_se = $fastAPD_obj->calculate_apd_std_err(method  => 'fast_apd',
                                                      compare => 'gap_base');
    is(round($fastapd_se), $expected_se, "check $alphabet fast_apd standard error");    
}



# Subroutines                                          

sub create_seq_array {
    my $file = shift;
    my @sequences;
                                                                      
    # Read in aligned sequence file (fasta format for this test)
    open(my $input_fh, '<', $file);
    chomp(my @fasta_lines = <$input_fh>);

    # Create an array of aligned sequences
    my $curr_seq;
    foreach my $line (@fasta_lines) {
        if (substr($line, 0, 1) eq ">") { 
            if ($curr_seq) { push(@sequences, $curr_seq) }
            $curr_seq = ();
        }
        else { $curr_seq .= $line }
    }
    if ($curr_seq) { push(@sequences, $curr_seq) }

    return(\@sequences);
}
                                                    
sub round {
    my $float = shift;
    return( sprintf("%.6f", $float) );
}
                                                            

