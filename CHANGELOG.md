## 0.1.4 (October 19, 2010)
  
Improvements:
  
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