namespace :libraoc do
  namespace :cleanup do

    desc "runs unescape to clean up characters like &gt; &quot; etc."
    task unescape_html: :environment do
      successes = 0
      errors = 0

      LibraWork.search_in_batches( {} ) do |group|
        group.each do |w|
          begin
            print "."

            title = ''
            cleaned_title = ''
            abstract = ''
            cleaned_abstract = ''
            update = false

            if w['title_tesim'].present?
              title = w['title_tesim'][ 0 ]
              cleaned_title = CGI.unescapeHTML title
              if title != cleaned_title
                puts "\nID: #{w['id']}"
                puts "old title: #{title}"
                puts "new title: #{cleaned_title}"
                update = true
              end
            end

            if w['description_tesim'].present?
              abstract = w['description_tesim'][ 0 ]
              cleaned_abstract = CGI.unescapeHTML abstract
              if abstract != cleaned_abstract
                puts "\nID: #{w['id']}"
                puts "old abstract: #{abstract}"
                puts "new abstract: #{cleaned_abstract}"
                update = true
              end
            end

            if update == true

              work = LibraWork.find( w['id'] )
              work.title = [cleaned_title] if cleaned_title.present?
              work.description = cleaned_abstract if cleaned_abstract.present?
              work.save!
            end

            successes += 1
          rescue => ex
            puts "EXCEPTION: #{ex}"
            errors += 1
          end
        end
      end

      puts "done"
      puts "Processed #{successes} work(s), #{errors} error(s) encountered"
    end
  end
end


