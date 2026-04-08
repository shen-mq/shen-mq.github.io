#import "../../index.typ": template, tufted
#show: template.with(title: "PDF 书签制作")

= PDF 书签制作方法

有的时候会下载到没有书签的扫描版电子书，这种电子书不方便跳转。这里介绍一个使用命令行工具制作 PDF 书签的方法。使用到的工具有 `pdf-bookmark` 和 python 的 `pagelabels` 模块。

整体流程：
+ PDF 的 page label 如果有问题的，可以用 `pagelabels` 先处理；
+ 用OCR工具或任何有视觉功能大语言模型，识别并给出 bkm 格式的书签;
+ 用 `pdf-bookmark` 工具给 PDF 加上书签。

== `pdf-bookmark` 工具

`pdf-bookmark` 是一个底层依赖 PDFtk 和 Ghostscript 的工具。直接用 Ghostscript 编写书签的语法比较繁杂，`pdf-bookmark` 就提供了一个更高级的封装，使得编写书签的语法（bmk 格式）比较简单。


=== bmk 格式

bmk 格式用于描述 PDF 文件的书签，并用于将书签导入 PDF 文件。

bmk 格式很容易编写，形式和书籍目录很接近，因此可以直接复制目录内容后再修改。

每一行表示一个书签项，标题和页码之间至少用 4 个点 `.` 分隔。

书签层级由前导空格缩进决定，默认缩进为 2 个空格，也可以通过内联命令配置缩进空格数。

下面是一个简单的 bmk 文件示例。

```
序................1
Chapter 1................4
Chapter 2................5
  2.1 Section 1................6
    2.1.1 SubSection 1................6
    2.1.2 SubSection 2................8
  2.2 Section 2................12
Chapter 3................20
Appendix................36
```

=== inline command

`pdf-bookmark` 支持在 `bmk` 文本中使用以 `!!!` 开头的内联命令，后续书签会持续受该命令影响，直到被新的同类命令覆盖。

常用命令如下：

+ `new_index`：默认 `1`。用于设置“当前页码体系的起始 PDF 物理页号”。
  对应换算：`actual = new_index + page - 1`。
+ `num_start`：默认 `1`。当该段页码不是从 1 开始时使用。
  对应换算：`actual = new_index + page - num_start`。
+ `num_style`：默认 `Arabic`，支持 `Arabic` / `Roman` / `Letters`。
+ `collapse_level`：默认 `0`，设置默认折叠层级。
+ `level_indent`：默认 `2`，设置缩进空格数。

`new_index` 含义就是，从这里开始，后续页码都要以此为基础。例如在 PDF 文档的15页是书籍正文第一章第一节的开始，这页标的页码自然是 1，而 bmk 文件里标的是“逻辑页码”，也就是书上写着的那个数字，即类似于下面这样
```
第1章 基本概念................1
```
所以要使得这个书签对应到真实的PDF的页数上，就需要加上 14。所以换算关系为`actual = new_index + page - 1`，`actual` 是 PDF 真实的页数，`page` 是逻辑上的、写在书上的页码。

== page label 和 bookmark

在 PDF 里，page label 和 bookmark 是两套独立机制。

page label（页标签）定义的是“这一页在阅读器中显示成什么页码”，它可以是 `1, 2, 3`，也可以是 `i, ii, iii`，甚至可能是扫描文件里遗留的 `fow0004.pdg` 这类字符串；它影响的是页码栏和页面缩略图中的编号显示。

bookmark（书签）定义的是“目录项点下去要跳到哪一页”，它影响的是左侧目录导航的层级和跳转位置。两者最关键的区别在于职责不同：bookmark 决定“跳转到哪里”，page label 决定“跳到那页后显示成几”。因此只做书签而不处理页标签时，目录可以跳对，但阅读器里看到的页码仍可能是 PDF 物理页号或旧标签；把页标签也设置正确后，目录跳转和页码显示才会和书上印刷页码一致。

== 处理 page label 的模块 —— `pagelabels`

`pagelabels` 是一个基于 pdfrw 的小型 Python 库，用于操作 PDF 的 page label。它可以从 PDF 解析 page label、编辑 page label，并将其写回 PDF。

可以通过下面命令安装
```bash
pip install pagelabels
```

`pagelabels` 的参数继承自 `PageLabelScheme`，而 `PageLabelScheme` 继承自 named tuple，包含以下字段：

- `startpage`：在 PDF 中按该方案开始编号的页索引
- `style`：可选值包括 `arabic`、`roman uppercase`、`letters uppercase`、`roman lowercase`、`letters lowercase`
- `prefix`：加在所有 page label 前面的字符串前缀
- `firstpagenum`：编号从哪个数开始

举一个例子，一本书从第3页（PDF文件的物理页码）开始是前言等内容，用罗马数字编号，第7页开始是正文内容，开始用阿拉伯数字编号，那么就可以用下面的命令编辑 page label：

```bash
python3 -m pagelabels --delete "book.pdf"

python3 -m pagelabels --startpage 3 \
  --type "roman lowercase" \
  --firstpagenum 1 \
  "book.pdf"

python3 -m pagelabels --startpage 7 \
  --type "arabic" \
  --firstpagenum 1 \
  "book.pdf"
```
