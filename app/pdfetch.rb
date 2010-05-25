##Original code from Edoardo as described below

## pdfetch
## v0.5
## 2010-05-18
##
## Original idea and code by
## Copyright (c) 2006, Edoardo "Dado" Marcora, Ph.D.
## <http://marcora.caltech.edu/>
##
## Heavily modified and updated by Bio-geeks 
## Copyright 2009 and 2010, Elfar Torarinsson and Morten Lindow
## <http://bio-geeks.com>
##    decoupled it from camping
##    refactored Finders to reduce replicated code
##    added logging
##    added tests for finders
##
## Released under the MIT license
## <http://www.opensource.org/licenses/mit-license.php>

require 'rubygems'
require 'mechanize'
require 'logger'
base_logfile = File.join(File.dirname(__FILE__), '..', 'log','pdfetch.log')
# base_logfile = STDERR
$LOG = Logger.new(base_logfile, 10)

class Reprint < Mechanize::File
  # empty class to use as Mechanize pluggable parser for pdf files
end

module Pdfetch
  class Fetcher
    attr_accessor :save_dir
  
    def useSocks(server,port)
      require 'socksify'
      TCPSocket::socks_server = server
      TCPSocket::socks_port = port
    end
  
    def get(id)
      @pmid = id.to_s
      @uri = "http://eutils.ncbi.nlm.nih.gov/entrez/eutils/elink.fcgi?dbfrom=pubmed&id=#{@pmid}&retmode=ref&cmd=prlinks&tool=pdfetch"
      success = false
      begin
        if File.exist?("#{@save_dir}/#{id}.pdf") # bypass finders if pdf reprint already stored locally
          success = true
          $LOG.info "We already have #{id}"
        else
          m = Mechanize.new { |a| 
            a.keep_alive = 1
            a.user_agent_alias = 'Mac Safari'
          }
          # set the mechanize pluggable parser for pdf files to the empty class Reprint, as a way to check for it later
          m.pluggable_parser.pdf = Reprint
          begin
            p = m.get(@uri)
            @uri = p.uri
            if p.uri.to_s =~ /www\.ncbi\.nlm\.nih\.gov/  # no full text link available
              $LOG.info "According to Pubmed no full text exists for #{id}"
              return false
            end
          rescue 
            $LOG.warn "Failed to get fulltext uri from ncbi #{@uri}"
            sleep(1)
            return false
            # we should do a retry
          end
          finders = Pdfetch::Finders.new
          # loop through all finders until it finds one that return the pdf reprint
          for finder in finders.public_methods(false).sort
             begin
               $LOG.debug "Trying #{finder.to_sym}"
               if page = finders.send(finder.to_sym, m,p)
                 if page.kind_of? Reprint
                   page.save_as("#{@save_dir}/#{id}.pdf")
                   $LOG.info "Succesfully downloaded #{id} using #{finder.to_sym}"
                   success = true
                   break
                 end
               end
             rescue
               $LOG.debug "#{id} failed using #{finder.to_sym}"
             end
          end
        end
        return success
      end
    end
  end


  class Finders
    # Finders are functions used to find the pdf reprint off a publisher's website.
    # Pass a finder the mechanize agent (m) and the pubmed linkout page (p), and
    # it will return either the pdf reprint or nil.

    def zeneric(m,p) # this finder has been renamed 'zeneric' instead of 'generic' to have it called last (as last resort)
        m.click p.links_with(:text  => /pdf|full[\s-]?text|reprint/i)[0]
    end

    def springer_link(m,p)
      m.click p.links_with(:href  => /fulltext.pdf$/i)[0]
    end

    def humana_press(m,p)
        page = m.click p.links_with(:href => /task=readnow/i)[0]
    end

    def blackwell_synergy(m,p)
        return nil unless p.uri.to_s =~ /\/doi\/abs\//i
        m.get(p.uri.to_s.sub('abs', 'pdf'))
    end

    def wiley(m,p)
        page = m.click p.links_with(:text => /pdf/i, :href => /pdfstart/i)[0]
        page = m.click page.frames_with(:name => /main/i, :src => /mode=pdf/i)[0]
    end

    def science_direct(m,p)
        return nil unless p.uri.to_s =~ /sciencedirect/i
        page = m.get(p.at('body').inner_html.scan(/http:\/\/.*sdarticle.pdf/).first)
    end

    #Sometimes there is an initial choice where one is sciencdirect
    def choose_science_direct(m,p)
        page = p.search('body').inner_html.scan(/value=\"(http:\/\/www.sciencedirect.com\/science.*?)"/).first
        page = m.get(page)
        page = m.get(page.search('body').inner_html.scan(/http:\/\/.*sdarticle.pdf/).first)        
    end

    def ingenta_connect(m,p)
        page = m.click p.links_with(:href => /mimetype=.*pdf$/i)[0]
    end

    def cell_press(m,p)
        page = m.click p.links_with(:text => /cell|cancer cell|developmental cell|molecular cell|neuron|structure|immunity|chemistry.+biology|cell metabolism|current biology/i).and.href(/cancercell|cell|developmentalcell|immunity|molecule|structure|current-biology|cellmetabolism|neuron|chembiol/i)[0]
        uid = /uid=(.+)/i.match(page.uri.to_s)
        if uid
          re = Regexp.new(uid[1])
          page = m.click page.links_with(:text => /pdf/i, :href => re)[0]
        else
          page = m.click page.links_with(:text => /pdf \(\d+K\)/i, :href => /\.pdf$/i)[0]
        end
        page
    end

    def jbc(m,p)
        page = m.click p.links_with(:text => /pdf/i, :href => /reprint/i)[0]
        page = m.click page.frames_with(:name => /reprint/i)[0]
        page = m.click page.links_with(:href => /.pdf$/i)[0]
    end

    def nature(m,p)
        # return nil if p.uri.to_s =~ /sciencedirect/i # think of a better way to skip this finder for sciencedirect reprints!
        page = m.click p.links_with(:text => /Download pdf/i, :href => /pdf$/i)[0]
        # page = m.click p.links_with(:text => /full text/i, :href => /full/i)[0]
        # page = m.click page.links_with(:href => /.pdf$/i)[0]
    end

    def nature_reviews(m,p)
        page = m.click p.frames_with(:name => /navbar/i)[0]
        page = m.click page.links_with(:href => /.pdf$/i)[0]
    end

    def pubmed_central(m,p)
        page = m.click p.links_with(:text => /pdf/i, :href => /blobtype=pdf/i)[0]
    end
    
    def genes_development(m,p)
      page = m.get(p.search("/html/head/meta[@name='citation_pdf_url']").first.get_attribute('content'))
    end
  

   # def pnas(m,p)
   #      page = p.search('head').inner_html.scan(/meta content=\"(http:\/\/www.pnas.org.*.pdf)\"/)
   #      page = m.get(page)
   #      page
   # end
   #   
   #  def coldspringharbour(m,p)
   #      page = p.search('head').inner_html.scan(/meta content=\"(http:\/\/.*cshlp.org.*full.pdf)\"/)
   #      page = m.get(page)
   #      page
   #  end

    # def unknown(m,p)
    #     page = m.click p.links_with(:href => /.pdf$/i)[0]
    # end
  
    def direct_pdf_link(m,p)
    end
  end
end