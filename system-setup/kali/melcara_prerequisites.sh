#!/bin/sh
#install dependencies for running nessus parser melcara.com#
# Melcara is a Nessus XML Parser that results in an Excel spreadsheet
#   of over 20 tabs, separating by severity, host details, and a Summary of metrics
# Pulled from: http://pen-testing.sans.org/blog/2014/04/29/data-data-everywhere-what-to-do-with-volumes-of-nessus-output/comment-page-1/
#

#update#
sudo apt-get update


#install dependencies#
sudo cpan install XML::TreePP
sudo cpan install Data::Dumper
sudo cpan install Math::Round
sudo cpan install Excel::Writer::XLSX
sudo cpan install Data::Table
sudo cpan install Excel::Writer::XLSX::Chart