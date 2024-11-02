# Pecha Printer

A little Rails app to offer an easy frontend for [generate-printable-pecha](https://github.com/jerefrer/generate-printable-pecha), a small python lib that turns a single-page pecha PDFs into an A3 or A4 PDF for printing multiple pecha pages per sheet, properly ordered so that you just have to cut twice, put one stack on top of the other, and have your pecha ready.

## Requirements (pdfjam, poppler, podofocrop)

````bash
sudo apt install texlive-extra-utils poppler-utils podofo-utils
````