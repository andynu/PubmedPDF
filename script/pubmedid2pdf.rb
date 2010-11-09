#!/usr/bin/env ruby 

# == Synopsis 
#   This program tries to download a PDF file for the given comma-separated pubmed IDs
#
# == Required GEMS
#     mechanize (0.9.3)
#     socksify (1.1.0) (if you plan on using SOCKS)
#     progressbar
#
# == Examples
#     pubmedid2pdf.rb 19508715,18677110,19450510,19450585
#
#   Other examples:
#    This example downloads through SOCKS, here we are using a localhost connection through port 9999
#    Meaning that you can ssh to your some server you have access to that can access some PDFs that you cannot, f.ex. your University
#    This is done with this command: ssh -D 9999 username@server in another terminal
#    To use SOCKS call the program with the server and the port, in this case 127.0.0.1 and 9999
#     pubmedid2pdf.rb 19508715 127.0.0.1 9999
#
# == Usage 
#    pubmedid2pdf.rb pubmedid/s [server] [port]
#
# == Author
#   Bio-geeks (adapted a script by Edoardo "Dado" Marcora, Ph.D.)
#   <http://bio-geeks.com>
#
# == Copyright
#   Copyright (c) 2009-2010 Bio-geeks. Licensed under the MIT License:
#   http://www.opensource.org/licenses/mit-license.php
require 'rdoc/usage'
require 'rubygems'
require 'progressbar'
require File.join(File.dirname(__FILE__), '..', 'app','pdfetch')

$LOG.level = Logger::INFO

pubmeds = ARGV[0]
server = ARGV[1]
port = ARGV[2]

pubmeds_array = Array.new
if (pubmeds.nil?)
  RDoc::usage() #exits app
end
if (File.exists?(pubmeds)) # read pubmed ids from file, one per line
  pubmeds_array = IO.readlines(pubmeds).map{|l| l.chomp}
else
  pubmeds_array = pubmeds.split(",")
end

fetcher = Pdfetch::Fetcher.new()
fetcher.save_dir = "pdf/"

if (!server.nil? && !port.nil?)
  fetcher.useSocks(server,port)
end

pbar = ProgressBar.new("Fetching pdfs...", pubmeds_array.size)
failures = 0
successes = 0
pubmeds_array.each do |p|
  pbar.inc
  if  fetcher.get(p)
    successes = successes +1
  else 
    failures = failures +1
    $LOG.info "Failed to fetch #{p}"
  end
end
pbar.finish
puts "#{successes} successes and #{failures} failures"