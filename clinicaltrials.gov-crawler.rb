require 'anemone'
HOST = 'http://clinicaltrials.gov'
PATH = '/ct2/'
BASE_URI = HOST + PATH + 'crawl/'
TRIAL_URI = HOST + PATH + 'show/NCT'
DISPLAY_XML = '?displayxml=true'

dir = ARGV.shift or raise "Usage: clinicaltrials.gov-crawler.rb dir_name"
FileUtils.mkdir_p(dir) unless File.exists?(dir)
dir += '/' unless dir.match(%r{/$})

Anemone.crawl(BASE_URI) do |anemone|
  anemone.focus_crawl do |page|
    # Follow only page on /crawl/
    page.links.keep_if { |link| link.to_s.match(%r{^#{BASE_URI}\d+}) }
  end

  anemone.on_every_page do |page|
    puts 'Follow: ' << page.url.to_s

    Anemone.crawl(page.url) do |anemone_trial|
      anemone_trial.focus_crawl do |page|
        page.links
          .keep_if do |link| 
            # Keep clinical trials only...
            link.to_s.match(%r{^#{TRIAL_URI}(\d+)})
            if $1
              begin
                # ... if they're not on disk 
                ! File.file?(dir + $1 + '.xml')
              rescue
                puts 'File error, aborting.'
                exit
              end
            end
          end
          .collect { |link| link += DISPLAY_XML }
      end

      anemone_trial.on_pages_like Regexp.new('^' + TRIAL_URI + '\d+' + Regexp.escape(DISPLAY_XML)) do |page|
        puts 'Save: ' << page.url.to_s
        Regexp.new('^' + TRIAL_URI + '(\d+)' + Regexp.escape(DISPLAY_XML)).match (page.url.to_s)
        File.open(dir + $1 + '.xml', 'w') do |file| 
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
