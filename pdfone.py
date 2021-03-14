from PyPDF2 import PdfFileReader, PdfFileWriter
import sys

if len(sys.argv) >=2 and len(sys.argv) <= 3:

    pdf_read_file = open(sys.argv[1], 'rb')
    pdf_output = PdfFileWriter()  # 实例一个 PDF文件编写器
    pdf_input = PdfFileReader(pdf_read_file)  # 将要分割的PDF内容格式话
    pdf_output.addPage(pdf_input.getPage(0))
    pdf_file=''
    if len(sys.argv) == 3:
        pdf_file = sys.argv[2]
    else :
        pdf_file = sys.argv[1].replace('.pdf', '-0.pdf')
    with open(pdf_file, 'wb') as fp:
        pdf_output.write(fp)

