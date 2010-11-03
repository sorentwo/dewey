## 0.2.5 (November 3, 2010)
    
  * Sheet (gid) support for spreadsheets
  * Delegate authentication, more reliable and no need for eval + alias_method
  * Fix spreadsheet calls not authenticating

## 0.2.4 (November 2, 2010)
  
  Additions:
    
    - Support downloading drawings
    - Support downloading presentations
    - Drawing mime support and validation
    - put! method to raise on failed requests

  Changes:

    - Add support for new style export options (exportFormat & format)

  Bugfixes:
  
    - Fix search results pulling the feed id and not just the entry id
    - Fix entries pulling the feed along with the resource id
    - Remove calls to blank?

## 0.2.3 (October 30, 2010)

  Additions:
  
    - #delete and #delete! accept an optional :trash option to send a resource
      to the trash, rather than being fully deleted.
    - #get and #elete by title. Handles exact matches only.
  
  Bugfixes:
    
    - Not setting the :format option on #get no longers raises

## 0.2.2 (October 27, 2010)

  Changes:

    - API Changes for get and put. All methods will use an options hash
      rather than ordered options.
    - Validation methods can accept either a string or a symbol
    - More error-resistant handling of nil values passed to validation methods

## 0.2.1 (October 26, 2010)

Additions:

  - delete! method. Raises an exception rather than returning false when
    operations fail.
  - search method. For retrieving one or more document:ids from a title query.

Bugfixes:

  - Actually delete files rather than sending them to the trash

## 0.2.0 (October 20, 2010)

Additions:
  
  - Class-wide authentication. You only have to set up authentication once and
    then utilize that in all successive calls.
  - All file operations are stateless (Dewey.put, Dewey.get, etc)
  - Store multiple authorizations simultaneously.
  
Changes:

  - Convert API change. Format is required, not an option.
  - No longer supports upload or download, instead use put or get.

## 0.1.4 (October 19, 2010)
  
Additions:
  
  - Handle bad mimetypes.
  - Modular validation
  - Removed service option, needless.
  - Automatic implicit authorization, removes need to call authorize! manually.

Bugfixes:
  
  - Prevent peer certificate warnings in 1.9
  - Fixed id extraction regex that prevented resources with dashes or underscores
    from being pulled.

## 0.1.3 (June 29, 2010)

Bugfixes:

  - Handle mime type changes for files with no extension.

## 0.1.2 (June 28, 2010)

Features:

  - Removed dependency on xmlsimple. Processing was so minimal it was pointless.

Bugfixes:

  - Handle files with no extension
  
---
## 0.1.1 (June 28, 2010)

Bugfixes:

  - Mandate ~ 1.3 version of rspec
  - Clear up YAML load issues
