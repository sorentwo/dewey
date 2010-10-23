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