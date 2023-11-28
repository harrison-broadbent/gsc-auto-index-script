# Google Search Console auto-indexing script (`gsc-auto-indexer`)

This script will automatically submit all your website URLs to Google Search Console for indexing (or re-indexing).

There are heaps of paid SEO tools available to automatically submit your sites to Google for indexing. They're great, but you can also use this script to do the same thing for free.

This script uses a Google Cloud Service Account to connect to your Google Search Console instance, pull in your sitemap, and submit each page automatically for indexing.

Plus, it's easy to get started.

## Setup

Setting up this script is easy. You just need to create a (free) Google Cloud service account, authenticate this script using the `.json` service account keys, then invite the service account to your Google Search Console account.

0. Clone this script and install packages

   Download this script directly, or clone it. Make sure you've got `ruby` installed locally, then run `bundle` to install all required packages —

   ```sh
   git clone git@github.com:harrison-broadbent/gsc-auto-index-script.git
   cd gsc-auto-index-script
   bundle
   ```

1. Create a service account in Google Cloud

   - Visit https://console.cloud.google.com/iam-admin/serviceaccounts and create a new service account (click the big `+ Create Service Account` button).
   - Click "Actions" > "Manage keys" > "Add key" > "Create new key" > "JSON". A `.json` key file will automatically download — move it into this project directory

2. Authenticate the script

   - Edit `script.rb` and change the line with `service_account_file = "_.json" to be the name of your `.json` key file.
   - For example,

   ```ruby
   service_account_file = "gsc-index-400005-b3da9e3fd4fc.json"
   ```

3. Invite your service account into your Google Search Console

   - Open Google Search Console and, in the sidebar, click "Settings" > "Users and Permissions" > "Add User" and enter the email of your service account
     - ie: "example@project-400005.iam.gserviceaccount.com"
     - Set the permissions for the account to "Owner"

4. Run the script!

   - Run `ruby script.rb` to start the script. It will automatically pull in the sites available in your Google Search Console, and let you choose between them.
   - Once you choose a site, it will parse the sitemap (from the URL within Google Search Console), and submit each page for indexing.

## Optional Configuration and Flags

### `INDEX_FROM_CSV`

If this flag is set `true`, the script will look for a CSV file called `urls.csv`. This file should contain a comma-separated list of URLs to index, like this —

```csv
https://example.com,https://example.com/about
```

This can be helpful for sites with a massive number of pages, so you can index a subset rather than all of them.

By default, this flag is set `false`.
