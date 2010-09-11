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

## Getting Started

First, create a new Dewey::Document instance using your google docs account and
password.

    dewey = Dewey::Document.new(:account => 'example.account', :password => 'example')

Next, choose a local document to upload or convert.

    document = File.new('my_document.doc')
    spreadsheet = File.new('my_spreadsheet.xls')

Finally, handle the upload, download, and delete manually or use the convenient
`convert` method.

    dewey.convert(document, :html)
    dewey.convert(spreadsheet, :csv)

## Testing

Until testing is converted to an offline solution you will have to provide some
credentials for testing. All that is required is a valid Google Docs account, no
fussing about with getting an application API.

By default the spec will look for a file called dewey.yml inside of the spec 
folder. The file should contain two lines:

    email: <your gmail account>
    password: <your gmail password>