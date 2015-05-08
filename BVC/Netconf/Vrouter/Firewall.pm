package BVC::Netconf::Vrouter::Firewall;

use strict;
use warnings;

use Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(Firewall);

use JSON -convert_blessed_universally;

#---------------------------------------------------------------------------
# 
#---------------------------------------------------------------------------
package Rule;

sub new {
    my $class = shift;
    my $tagnode = shift;

    my $self = {
        'tagnode' => $tagnode,
        @_
    };
    bless ($self, $class);
}

sub add_action {
    my $self = shift;
    my $action = shift;

    $self->{action} = $action;
}

sub get_name {
    my $self = shift;

    return $self->{tagnode};
}

#---------------------------------------------------------------------------
# 
#---------------------------------------------------------------------------
package Group;

sub new {
    my $class = shift;
    my $tagnode = shift;

    my $self = {
        tagnode => $tagnode,
        rule => []
    };
    bless ($self, $class);
}

sub get_name {
    my $self = shift;
    return $self->{tagnode};
}



#---------------------------------------------------------------------------
# 
#---------------------------------------------------------------------------
package BVC::Netconf::Vrouter::Firewall;

sub new {
    my $class = shift;
    my $self = {
        name => []
    };
    bless ($self, $class);
}

sub as_json {
    my $self = shift;

    my $json = new JSON->canonical->allow_blessed->convert_blessed;
    return $json->pretty->encode($self);
}

sub add_group {
    my $self = shift;
    my $name = shift;

    my $group = new Group($name);
    push $self->{name}, $group;
}

sub get_group {
    my $self = shift;
    my $name = shift;

    my @groups = $self->{name};
    foreach my $groupref (@{ $self->{name} }) {
        if ($groupref->{tagnode} eq $name) {
            return $groupref;
        }
    }
    return undef;
}

sub add_rule {
    my $self       = shift;
    my $group_name = shift;
    my $rule_id    = shift;

    my $rule = new Rule($rule_id, @_);
    my $group = $self->get_group($group_name);
    push $group->{rule}, $rule;
}

sub get_rule {
    my $self = shift;

    # XXX
}

sub get_rules {
    my $self = shift;

    my @rules = ();
    foreach my $rule (@{ $self->{name} }) {
        push @rules, $rule;
    }
    return @rules;
}

sub get_payload {
    my $self = shift;

    my $json = new JSON->canonical->allow_blessed->convert_blessed;
    my $payload = '{"vyatta-security:security":{"vyatta-security-firewall:firewall":'
        . $json->encode($self)
        . '}}';
    $payload =~ s/"src_addr":"([0-9\.]*)"/"source":{"address":"$1"}/g;
    $payload =~ s/typename/type-name/g;
    return $payload;
}

sub get_url_extension {
    my $self = shift;

    return "vyatta-security:security/vyatta-security-firewall:firewall";
}

1;
