from markdown_pdf import MarkdownPdf, Section

pdf = MarkdownPdf(toc_level=2)
with open("documentation.md", "r", encoding="utf-8") as f:
    content = f.read()

pdf.add_section(Section(content, toc=False))
pdf.save("Documentacion_InClass.pdf")
print("PDF created successfully!")
