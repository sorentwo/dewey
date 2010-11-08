    :::::::::  :::::::::: :::       ::: :::::::::: :::   ::: 
    :+:    :+: :+:        :+:       :+: :+:        :+:   :+: 
    +:+    +:+ +:+        +:+       +:+ +:+         +:+ +:+
    +#+    +:+ +#++:++#   +#+  +:+  +#+ +#++:++#     +#++:
    +#+    +#+ +#+        +#+ +#+#+ +#+ +#+           +#+
    #+#    #+# #+#         #+#+# #+#+#  #+#           #+#
    #########  ##########   ###   ###   ##########    ###


# Light, simple Google Docs library for Ruby.

Dewey focuses on the simple cases of authorizing, searching, and managing the
files on a Google Docs account. Really, it stemmed from the need to use Docs
great document conversion services.

## Note

Dewey is in alpha. It is not recommended you use this in production code.

## Authentication

You can configure Dewey to connect with ClientLogin. 

ClientLogin

    Dewey.authentication :client, :email => 'example@gmail.com', :password => 'password'

AuthSub and OAuth support is planned for a future release.

## File Operations

You can put, get, delete and convert documents, spreadsheets or presentations in
any of the formats that Docs accepts. There is a full listing in dewey/validations.rb
or available here: http://code.google.com/apis/documents/faq.html#WhatKindOfFilesCanIUpload

Be sure to set up authorization before attempting any file operations! You don't
need to explictely call authorize though, as it will attempt to do that on the
first operation.

### Putting a Document

    document = File.new('my_document.doc')
    resource = Dewey.put(document, :title => 'My First Upload') #=> 'document:12345'

### Searching Documents

Exact search

    Dewey.search('My Document', :exact => true) #=> ['document:12345']

Loose search

    ids = Dewey.search('notes') #=> ['document:12', 'document:456']

### Getting a Document

Upload your file

    id = Dewey.put(File.new('my_document.doc'), 'My Second Upload')

Get it in various formats

    original = Dewey.get(id)                #=> Tempfile
    pdf  = Dewey.get(id, :format => :pdf)   #=> Tempfile
    html = Dewey.get(id, :format => :html)  #=> Tempfile

A tempfile is returned, so you'll have to move it

    FileUtils.mv html.path, 'path/to/destination'

Getting a document by title. Since only one file will be returned at a time you
must use an exact match.

    Dewey.get('My Document') #=> Tempfile
    Dewey.get('No Match')    #=> nil

Other file types are supported as well, including spreadsheets, drawings and
presentations:

    Dewey.get('Mine')               #=> ['presentation:12345', 'spreadsheet:12345', 'drawing:12345']
    Dewey.get('presentation:12345') #=> Tempfile
    Dewey.get('spreadsheet:12345')  #=> Tempfile
    Dewey.get('drawing:12345')      #=> Tempfile

### Deleting a Document

Deleting a document from a resource id

    id = Dewey.put(File.new('my_spreadsheet.xls'))
    Dewey.delete(id) #=> true

Deleting by title. Unmatched searches return false

    Dewey.delete('My Document') #=> true
    Dewey.delete('No Match')    #=> false

Sending to the trash rather than deleting

    Dewey.delete('My Document', :trash => true) #=> true

If you would prefer an error when deletion fails

    Dewey.delete!('My Document') #=> raise DeweyException
