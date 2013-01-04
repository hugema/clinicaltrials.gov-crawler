DIR = '../clinicaltrial.gov-data/'

require 'anemone'
HOST = 'http://clinicaltrial.gov'
PATH = '/ct2/'
BASE_URI = HOST + PATH + 'crawl/'
TRIAL_URI = HOST + PATH + 'show/NCT'
DISPLAY_XML = '?displayxml=true'

Anemone.crawl(BASE_URI) do |anemone|
  anemone.focus_crawl do |page|
    page.links.keep_if { |link| link.to_s.match(%r{#{BASE_URI}\d+}) }
  end

  anemone.on_every_page do |page|
    puts 'Follow: ' << page.url.to_s

    Anemone.crawl(page.url) do |anemone_trial|
      anemone_trial.focus_crawl do |page|
        page.links
          .keep_if { |link| link.to_s.match(%r{#{TRIAL_URI}\d+}) }
          .collect { |link| link += DISPLAY_XML }
          .keep_if do |link| 
            link.to_s.match(%r{#{TRIAL_URI}(\d+)})
            begin
              ! File.file?(DIR + $1 + '.xml')
            rescue
              puts 'File error, aborting.'
              exit
            end
          end
      end

      anemone_trial.on_pages_like Regexp.new(TRIAL_URI + '\d+' + Regexp.escape(DISPLAY_XML)) do |page|
        puts 'Save: ' << page.url.to_s
        Regexp.new(TRIAL_URI + '(\d+)' + Regexp.escape(DISPLAY_XML)).match (page.url.to_s)
        File.open(DIR + $1 + '.xml', 'w') do |file| 
          begin
            file.puts page.body 
          rescue
            puts 'File error, aborting.'
            exit
          ensure
            file.close unless file.nil?
          end
        end
      end
    end
  end
end
