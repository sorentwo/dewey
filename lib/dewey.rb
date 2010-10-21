module Dewey
  GOOGLE_DOCS_URL  = "https://docs.google.com"
  GOOGLE_SPRD_URL  = "https://spreadsheets.google.com"
  GOOGLE_LOGIN_URL = "https://www.google.com/accounts/ClientLogin"
  
  GOOGLE_FEED_URL        = GOOGLE_DOCS_URL + "/feeds/default/private/full"
  GOOGLE_DOCUMENT_URL    = GOOGLE_DOCS_URL + "/feeds/download/documents/Export"
  GOOGLE_SPREADSHEET_URL = GOOGLE_SPRD_URL + "/feeds/download/spreadsheets/Export"
  
  class DeweyException < Exception; end
end

require 'dewey/document'
require 'dewey/https'
require 'dewey/mime'
require 'dewey/utils'
require 'dewey/validation'