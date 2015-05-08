package BVC::Util::Status;

# XXX perldoc

use strict;
use warnings;

#use YAML;
#use LWP;
use HTTP::Status qw(:constants :is status_message);
#use JSON;
#use XML::Parser;
use Readonly;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(Status
                 $BVC_OK
                 $BVC_CONN_ERROR
                 $BVC_DATA_NOT_FOUND
                 $BVC_BAD_REQUEST
                 $BVC_UNAUTHORIZED_ACCESS
                 $BVC_INTERNAL_ERROR
                 $BVC_NODE_CONNECTED
                 $BVC_NODE_DISCONNECTED
                 $BVC_NODE_NOT_FOUND
                 $BVC_NODE_CONFIGURED
                 $BVC_HTTP_ERROR
                 $BVC_MALFORMED_DATA
                 $BVC_UNKNOWN
);

Readonly our $BVC_OK                  =>  0;
Readonly our $BVC_CONN_ERROR          =>  1;
Readonly our $BVC_DATA_NOT_FOUND      =>  2;
Readonly our $BVC_BAD_REQUEST         =>  3;
Readonly our $BVC_UNAUTHORIZED_ACCESS =>  4;
Readonly our $BVC_INTERNAL_ERROR      =>  5;
Readonly our $BVC_NODE_CONNECTED      =>  6;
Readonly our $BVC_NODE_DISCONNECTED   =>  7;
Readonly our $BVC_NODE_NOT_FOUND      =>  8;
Readonly our $BVC_NODE_CONFIGURED     =>  9;
Readonly our $BVC_HTTP_ERROR          => 10;
Readonly our $BVC_MALFORMED_DATA      => 11;
Readonly our $BVC_UNKNOWN             => 12;
Readonly my $BVC_FIRST = $BVC_OK;
Readonly my $BVC_LAST  = $BVC_UNKNOWN;

sub new {
    my $caller = shift;
    my $self = {
        code => $BVC_UNKNOWN,
        http_resp => undef,
        @_
    };
    bless $self, $caller;
}

sub set {
    my ($self, $status) = @_;
    if (($status >= $BVC_FIRST) && ($status <= $BVC_LAST)) {
        $self->{code} = $status;
    }
    else {
        $self->{code} = $BVC_UNKNOWN;
    }
    return $self->{code};
}

sub to_string {
    my $self = shift;

    my $status = $self->{code};
    my $errmsg = ($status == $BVC_OK)                  ? "Success"
               : ($status == $BVC_CONN_ERROR)          ? "Server connection error"
               : ($status == $BVC_DATA_NOT_FOUND)      ? "Requested data not found"
               : ($status == $BVC_BAD_REQUEST)         ? "Bad or invalid data in request"
               : ($status == $BVC_UNAUTHORIZED_ACCESS) ? "Server unauthorized access"
               : ($status == $BVC_INTERNAL_ERROR)      ? "Internal server error"
               : ($status == $BVC_NODE_CONNECTED)      ? "Node is connected"
               : ($status == $BVC_NODE_DISCONNECTED)   ? "Node is disconnected"
               : ($status == $BVC_NODE_NOT_FOUND)      ? "Node not found"
               : ($status == $BVC_NODE_CONFIGURED)     ? "Node is configured"
               : ($status == $BVC_HTTP_ERROR)          ? "HTTP error"
               : ($status == $BVC_MALFORMED_DATA)      ? "Malformed data"
               : ($status == $BVC_UNKNOWN)             ? "Unknown error"
               :                                        "Undefined status code " . $status;
    if (($status == $BVC_HTTP_ERROR)
        && $self->{http_resp}
        && $self->{http_resp}->code
        && $self->{http_resp}->message) {
            $errmsg += " " . $self->{http_resp}->code
                . " - "
                . $self->{http_resp}->message;
    }
    return $errmsg;
}

