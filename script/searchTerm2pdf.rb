#!/usr/bin/env ruby 

USAGE = <<DOC
== Synopsis 
  This program tries to download a PDF file for the given search term

== Required GEMS
    mechanize (0.9.3)
    bio (1.3.0)
    socksify (1.1.0) (if you plan on using SOCKS)

== Examples
    searchTerm2pdf.rb 'Torarinsson E[Author]' > list
    NB! The output list is just like a .csv file except that we use '|' and not ',' as a separator

  Other examples:
   This example downloads through SOCKS, here we are using a localhost connection through port 9999
   Meaning that you can ssh to your some server you have access to that can access some PDFs that you cannot, f.ex. your University
   This is done with this command: ssh -D 9999 username@server in another terminal
   To use SOCKS call the program with the server and the port, in this case 127.0.0.1 and 9999
    searchTerm2pdf.rb 'Torarinsson E[Author]' 127.0.0.1 9999

== Usage 
   searchTerm2pdf.rb search-term [server] [port] > list

== Author
  Bio-geeks (adapted a script by Edoardo "Dado" Marcora, Ph.D.)
  <http://bio-geeks.com>

== Copyright
  Copyright (c) 2009 Bio-geeks. Licensed under the MIT License:
  http://www.opensource.org/licenses/mit-license.php
DOC

require 'rubygems'
require 'bio'
require 'date'
require File.join(File.dirname(__FILE__), '..', 'app','pdfetch')

#query = '(Lindow M[Author] OR Torarinsson E[Author] OR Lindgreen S[Author] OR Marstrand T[Author]) AND (1998/01/01[PDAT]:3000[PDAT])'
#query = "Torarinsson"
query = ARGV[0]

if (query.nil?)
  puts USAGE
  exit
end

ids = Bio::PubMed.esearch(query, {'retmax' => 5000})
warn "Found #{ids.length} articles matching your search term: #{query}"

if ids.length > 0
  puts "pubmedid|first_author|last_author|journal|publication_type,title|affiliations|doi|mesh|year|abstract"
else
  warn "Couldn't find any articles matching your search term"  
end

fetcher = Pdfetch::Fetcher.new()

save_dir = Dir.pwd + "/pdf/"
if (!File.directory?(save_dir))
  Dir.mkdir(save_dir)
  puts "Made directory for #{save_dir} for the pdfs"
end
fetcher.save_dir = save_dir

server = ARGV[1]
port = ARGV[2]
if (!server.nil? && !port.nil?)
  fetcher.useSocks(server,port)
end

results = {}
ids.reverse.each do |pubmedid|
  manuscript = Bio::PubMed.efetch(pubmedid)
  m = Bio::MEDLINE.new(manuscript.first)
  
  pt = "Original research"
  allpt=m.publication_type.join("")
  pt = "Review" if allpt =~ /review/i
  pt = "Comment" if allpt =~ /comment/i
  pt = "News" if allpt =~ /news/i
    
  pubmedid = m.pmid
  first_author = m.authors.first
  last_author = m.authors.last
  journal = m.journal
  publication_type = pt
  title = m.title
  affiliations = m.affiliations.join(';').gsub(/\-/, "")
  doi = m.doi
  mesh = m.mesh.join(", ")
  year = m.year
  abstract = m.abstract
  
  print "#{pubmedid}|#{first_author}|#{last_author}|#{journal}|#{publication_type}|#{title}|#{affiliations}|#{doi}|#{mesh}|#{year}|"
  #|#{abstract}"
  
  #warn "Attempting to fetch the PDF file for the following article:
  #      Title: #{title}
  #      First author: #{first_author}
  #      Last author: #{last_author}
  #      Journal: #{journal}"
        
  ok = fetcher.get(pubmedid)
  results[ok] ||= 0
  results[ok] += 1

  if ok
    puts "OK"
  else
    puts "FAILED"
  end
  
end
puts results.inspect
