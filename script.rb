require "googleauth" # google client login
require "google/apis/searchconsole_v1"
require "open-uri" # sitemap parsing
require "xmlsimple"
require "tty-prompt" # terminal prompts

require "csv" # optional csv parsing

## Optional Flags
#
# If this is set to true, the script read from a CSV file called "urls.csv"
# This file should contain URLs that you want to index for your site.
# If this flag is true, we will SKIP parsing your sitemap and just use the urls.csv values directly.
INDEX_FROM_CSV = false

# Preface: functions we use later on #
def get_all_site_urls(service)
  sites = service.list_sites
  sites.site_entry.map { |site| site.site_url }
end

# Get the sitemap URL from within Google Search Console, for a selected site
# site_url: string: "https://example.com" | "sc-domain:example.com"
def get_sitemap_url(service, site_url)
  sitemaps = service.list_sitemaps(site_url)
  sitemaps.sitemap[0].path
end

# Get and parse the sitemap of a URL into individual URLs
def get_all_pages_from_sitemap(url)
  xml_data = URI.open(url).read
  data = XmlSimple.xml_in(xml_data)
  links = data["url"].map { |url| url["loc"][0] }
end

def get_all_pages_from_csv(path)
  urls = []
  CSV.foreach(path) do |row|
    # Since all URLs are in one line, just grab the first line
    urls = row
  end
  urls
end

# Submit a single page url for indexing to Google Search Console
def submit_index_request(service, site_url, page_url)
  request = Google::Apis::SearchconsoleV1::InspectUrlIndexRequest.new
  request.inspection_url = page_url
  request.site_url = site_url
  response = service.inspect_url_index(request)

  return response
end

### Step 0: Get setup in Google Cloud and Google Search Console
# Create a new service account —
# - Visit https://console.cloud.google.com/iam-admin/serviceaccounts and create a new service account
# - Click "Actions" > "Manage keys" > "Add key" > "Create new key" > "JSON", and move the ".json" file into the same directory as this script
# - Edit "service_account_file" to match the name of your key — 
#
service_account_file = "gsc-index-400005-b3da9e3fd4fc.json"
#
# - Invite your service account into your Google Search Console
# - Search Console > "Settings" > "Users and Permissions" > "Add User" and enter the email of your service account
#   - ie: "example@project-400005.iam.gserviceaccount.com"
#   - Set permissions to "Owner"

### Step 1: Create and auth client with Google APIs
scope = "https://www.googleapis.com/auth/webmasters"
authorizer = Google::Auth::ServiceAccountCredentials.make_creds(
  json_key_io: File.open(service_account_file),
  scope: scope,
)

authorizer.fetch_access_token!
service = Google::Apis::SearchconsoleV1::SearchConsoleService.new
service.authorization = authorizer

### Step 2: Run app
prompt = TTY::Prompt.new

# pick a site from all the ones we have access to
all_site_urls = get_all_site_urls(service)
selected_site_url = prompt.select("Select a site — ", all_site_urls)

# determine which pages to index
pages_to_index = []

if INDEX_FROM_CSV
  # If this flag is enabled, pull pages from CSV
  csv_pages = get_all_pages_from_csv("urls.csv")
  pp "Found #{csv_pages.count} pages in urls.csv — "
  pp csv_pages

  pages_to_index = csv_pages
else
  # Otherwise, fetch sitemap and pull pages from it
  # get the sitemap URL from GSC, then parse it an extract all pages
  sitemap_url = get_sitemap_url(service, selected_site_url)
  sitemap_pages = get_all_pages_from_sitemap(sitemap_url)
  pp "Found #{sitemap_pages.count} pages in sitemap for #{selected_site_url} — "
  pp sitemap_pages

  pages_to_index = sitemap_pages
end

# do the indexing
should_index = prompt.yes?("Should we submit all these pages for (re)indexing?")
if should_index
  pages_to_index.each do |page|
    response = submit_index_request(service, selected_site_url, page)

    current_status = response.inspection_result.index_status_result.coverage_state
    last_crawled = response.inspection_result.index_status_result.last_crawl_time
    pp "(#{page}) | Current status: #{current_status} | Last crawled: #{last_crawled.nil? ? "never" : Time.new(last_crawled).localtime}"
  end
  pp "indexed #{pages_to_index.count} pages for #{selected_site_url}"
end

pp "Done."
