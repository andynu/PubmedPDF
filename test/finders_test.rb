require File.join(File.dirname(__FILE__), '..', 'app', 'pdfetch')
require 'test/unit'

class FinderTest < Test::Unit::TestCase
  def setup
    @fetcher =  Pdfetch::Fetcher.new()
    STDERR.puts "Running tests using SOCKS proxy"
    server = "127.0.0.1"
    port = 9999
    @fetcher.useSocks(server,port)
    teardown
    FileUtils.mkdir 'temp/'
    @fetcher.save_dir = "temp/"
  end
  
  def teardown
    if File.exists? 'temp/'
      FileUtils.rm_r Dir.glob('temp/*')
      FileUtils.rmdir 'temp/'
    end
  end
  
  
  def test_choose_science_direct
    assert @fetcher.get(9441800)
  end
  
  def test_wiley
    assert @fetcher.get(9303515)
  end
  
  def test_unknown
    assert @fetcher.get(9252069)
  end
  
  def test_jbc
    assert @fetcher.get(9016671)
  end
  
  def test_blackwell_synergy
    assert @fetcher.get(18095875)
  end
  
  def test_springer_link
    assert @fetcher.get(16988763)
  end
  
  def test_genes_development
    assert @fetcher.get(20413612)
  end
  
  def test_nature
    assert @fetcher.get(18368051)
  end
  
  def test_gene_therapy # nature press
    assert @fetcher.get(16453009)
  end
  
  def test_nar
    assert @fetcher.get(18158304)
  end
  
  def test_bmc
    assert @fetcher.get(20074352)
  end
  
end