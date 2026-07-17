#!/usr/bin/env bash
# Resolve a release from one of the official Antigravity /releases APIs.
#
# Usage: resolve-release.sh <releases-api> [version]
# Prints two lines:
#   <version>
#   <execution-id>
#
# With no version, the highest semantic version is selected.  When Google
# republishes the same version, the first entry returned by the API wins.
set -euo pipefail

API="${1:?releases API URL required}"
REQUESTED_VERSION="${2:-}"

json="$(curl -fsSL "$API")"

printf '%s' "$json" | REQUESTED_VERSION="$REQUESTED_VERSION" perl -MJSON::PP -0777 -e '
  use strict;
  use warnings;

  my $requested = $ENV{REQUESTED_VERSION} // q{};
  my $releases = decode_json(<STDIN>);
  die "releases API did not return a JSON array\n" if ref($releases) ne "ARRAY";

  my ($selected_version, $selected_id);
  for my $release (@{$releases}) {
    next if ref($release) ne "HASH";
    my $version = $release->{version} // q{};
    my $id = $release->{execution_id} // q{};
    $id =~ s{/+\z}{};
    next if $version !~ /^\d+\.\d+\.\d+\z/ || $id !~ /^\d+\z/;

    if (length $requested) {
      if ($version eq $requested) {
        ($selected_version, $selected_id) = ($version, $id);
        last;
      }
      next;
    }

    if (!defined $selected_version || version_cmp($version, $selected_version) > 0) {
      ($selected_version, $selected_id) = ($version, $id);
    }
  }

  if (!defined $selected_version) {
    my $message = length $requested
      ? "version $requested not found in releases API"
      : "releases API contained no valid releases";
    die "$message\n";
  }

  print "$selected_version\n$selected_id\n";

  sub version_cmp {
    my ($left, $right) = @_;
    my @left = map { 0 + $_ } split /\./, $left;
    my @right = map { 0 + $_ } split /\./, $right;
    for my $index (0 .. 2) {
      my $difference = $left[$index] <=> $right[$index];
      return $difference if $difference;
    }
    return 0;
  }
'
