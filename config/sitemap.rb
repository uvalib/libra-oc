# Set the host name for URL creation
SitemapGenerator::Sitemap.default_host = "https://libraopen.lib.virginia.edu"

SitemapGenerator::Sitemap.create do
  constraints = "read_access_group_ssim:public"
  LibraWork.search_in_batches( constraints, {:rows => 999} ) do |group|
    group.each do |work|
      modified_at = Date.parse(work['date_modified_dtsi'])
      add public_view_path(work['id']), lastmod: modified_at
    end
  end

  # Put links creation logic here.
  #
  # The root path '/' and sitemap index file are added automatically for you.
  # Links are added to the Sitemap in the order they are specified.
  #
  # Usage: add(path, options={})
  #        (default options are used if you don't specify)
  #
  # Defaults: :priority => 0.5, :changefreq => 'weekly',
  #           :lastmod => Time.now, :host => default_host
  #
  # Examples:
  #
  # Add '/articles'
  #
  #   add articles_path, :priority => 0.7, :changefreq => 'daily'
  #
  # Add all articles:
  #
  #   Article.find_each do |article|
  #     add article_path(article), :lastmod => article.updated_at
  #   end
end
