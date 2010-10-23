    :::::::::  :::::::::: :::       ::: :::::::::: :::   ::: 
    :+:    :+: :+:        :+:       :+: :+:        :+:   :+: 
    +:+    +:+ +:+        +:+       +:+ +:+         +:+ +:+  
    +#+    +:+ +#++:++#   +#+  +:+  +#+ +#++:++#     +#++:   
    +#+    +#+ +#+        +#+ +#+#+ +#+ +#+           +#+    
    #+#    #+# #+#         #+#+# #+#+#  #+#           #+#    
    #########  ##########   ###   ###   ##########    ###

Dewey allows you to simply upload, download and delete files from your Google
Docs account.

Let Google do all of the hard work of converting your documents!

## Note

Dewey is in alpha. It is not recommended you use this in production code.

## Authorization

You can configure Dewey to connect with either ClientLogin or OAuth. If you choose
OAuth you'll only have to authenticate the first time you connect and subsequent
connections will use the saved token.

ClientLogin

    Dewey.authorization :client, :email => 'example@gmail.com', :password => 'password'
    
OAuth

    Dewey.authorization :oauth, :idontknowwhatgoeshereyet

## File Operations

You can put, get, delete and convert documents, spreadsheets or presentations in
any of the formats that Docs accepts. There is a full listing in dewey/validations.rb
or available here: http://code.google.com/apis/documents/faq.html#WhatKindOfFilesCanIUpload

Be sure to set up authorization before attempting any file operations! You don't
need to explictely call authorize though, as it will attempt to do that on the
first operation.

Putting a document:

    document = File.new('my_document.doc')
    resource = Dewey.put(document, 'My First Upload') # Returns the id when successful

Getting a document:

    # Upload your file
    id = Dewey.put(File.new('my_document.doc'), 'My Second Upload')
    
    # Get it in various formats
    original = Dewey.get(id)     # -> Tempfile
    pdf  = Dewey.get(id, :pdf)   # -> Tempfile
    html = Dewey.get(id, :html)  # -> Tempfile
    
    # A tempfile is returned, so you'll have to move it
    FileUtils.mv html.path, 'path/to/destination'

Deleting a document:

    id = Dewey.put(File.new('my_spreadsheet.xls'))
    result = Dewey.delete(id) # -> true