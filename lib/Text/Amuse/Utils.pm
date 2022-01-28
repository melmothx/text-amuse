package Text::Amuse::Utils;

use utf8;
use strict;
use warnings;

=head1 NAME

Text::Amuse::Output - Internal module for L<Text::Amuse> output

=head1 FUNCTIONS

=head2 language_mapping

Return an hashref with the ISO language codes to Babel ones.

=head2 get_latex_lang($iso)

Return the babel name of the ISO language code. If missing or invalid return 'english'.

=cut



sub language_mapping {
        return {
                ar => 'arabic', # R2L
                bg => 'bulgarian',
                ca => 'catalan',
                cs => 'czech',
                da => 'danish',
                de => 'german',
                el => 'greek',
                en => 'english',
                eo => 'esperanto',
                es => 'spanish',
                et => 'estonian',
                fa => 'farsi',  # R2L
                fi => 'finnish',
                fr => 'french',
                id => 'indonesian',
                ga => 'irish',
                gl => 'galician',
                he => 'hebrew', # R2L
                hi => 'hindi',
                hr => 'croatian',
                hu => 'magyar',
                is => 'icelandic',
                it => 'italian',
                lo => 'lao',
                lv => 'latvian',
                lt => 'lithuanian',
                ml => 'malayalam',
                ms => 'malay',
                mk => 'macedonian', # needs workaround
                mr => 'marathi',
                nl => 'dutch',
                no => 'norsk',
                nn => 'nynorsk',
                oc => 'occitan',
                sr => 'serbian',
                ro => 'romanian',
                ru => 'russian',
                sk => 'slovak',
                sl => 'slovenian',
                pl => 'polish',
                pt => 'portuges',
                sq => 'albanian',
                sv => 'swedish',
                tr => 'turkish',
                tl => 'filipino',
                uk => 'ukrainian',
                vi => 'vietnamese',
                zh => 'chinese',
                ja => 'japanese',
                ko => 'korean',
                th => 'thai',
                km => 'khmer',
                my => 'burmese',
               };
}

sub get_latex_lang {
    my $lang = shift || 'en';
    return language_mapping()->{$lang} || 'english';
}

1;
