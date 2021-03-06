# --
# Copyright (C) 2001-2017 OTRS AG, http://otrs.com/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

use strict;
use warnings;
use utf8;

use vars (qw($Self));

use Kernel::System::EmailParser;

# get config object
my $ConfigObject = $Kernel::OM->Get('Kernel::Config');

# get helper object
$Kernel::OM->ObjectParamAdd(
    'Kernel::System::UnitTest::Helper' => {
        RestoreDatabase => 1,
    },
);
my $Helper = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');

# do not really send emails
$ConfigObject->Set(
    Key   => 'SendmailModule',
    Value => 'Kernel::System::Email::DoNotSendEmail',
);

# test scenarios
my @Tests = (
    {
        Name => 'DefaultHeader',
        Data => {
            From    => 'john.smith@example.com',
            To      => 'john.smith2@example.com',
            Subject => 'some subject',
            Body    => 'Some Body',
            Type    => 'text/plain',
            Charset => 'utf8',
        },
        Check => {
            'Precedence:'     => 'bulk',
            'Auto-Submitted:' => 'auto-generated',
        },
    },
    {
        Name => 'DefaultHeader - X-Header',
        Data => {
            From    => 'john.smith@example.com',
            To      => 'john.smith2@example.com',
            Subject => 'some subject',
            Body    => 'Some Body',
            Type    => 'text/plain',
            Charset => 'utf8',
        },
        Check => {
            'X-OTRS-Test' => 'DefaultHeader',
        },
    },
);

my $Count = 1;
for my $Test (@Tests) {

    my $Name = "#$Count $Test->{Name}";

    $Kernel::OM->ObjectsDiscard( Objects => ['Kernel::System::Email'] );
    my $EmailObject = $Kernel::OM->Get('Kernel::System::Email');

    # do not really send emails
    $ConfigObject->Set(
        Key   => 'Sendmail::DefaultHeaders',
        Value => $Test->{Check},
    );

    my ( $Header, $Body ) = $EmailObject->Send(
        %{ $Test->{Data} },
    );

    # end MIME::Tools workaround
    my $Email = ${$Header} . "\n" . ${$Body};
    my @Array = split /\n/, $Email;

    # parse email
    my $ParserObject = Kernel::System::EmailParser->new(
        Email => \@Array,
    );

    # check header
    KEY:
    for my $Key ( sort keys %{ $Test->{Check} || {} } ) {
        next KEY if !$Test->{Check}->{$Key};
        $Self->Is(
            $ParserObject->GetParam( WHAT => $Key ),
            $Test->{Check}->{$Key},
            "$Name GetParam(WHAT => '$Key')",
        );
    }
}

# cleanup is done by RestoreDatabase

1;
