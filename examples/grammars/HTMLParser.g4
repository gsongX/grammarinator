/*
 [The "BSD licence"]
 Copyright (c) 2013 Tom Everett
 All rights reserved.

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:
 1. Redistributions of source code must retain the above copyright
    notice, this list of conditions and the following disclaimer.
 2. Redistributions in binary form must reproduce the above copyright
    notice, this list of conditions and the following disclaimer in the
    documentation and/or other materials provided with the distribution.
 3. The name of the author may not be used to endorse or promote products
    derived from this software without specific prior written permission.

 THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
 IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
 OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
 IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT,
 INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
 NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
 THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

// TEST-PROCESS: {grammar}Parser.g4 {grammar}Lexer.g4 -o {tmpdir}
// TEST-GENERATE: {grammar}Generator -r htmlDocument -t HTMLGenerator.html_space_transformer -n 5 -o {tmpdir}/{grammar}G%d.html
// TEST-GENERATE: ../fuzzer/{grammar}CustomGenerator.py -r htmlDocument -t HTMLGenerator.html_space_transformer -n 5 -o {tmpdir}/{grammar}C%d.html

parser grammar HTMLParser;

options { tokenVocab=HTMLLexer;
          dot=any_unicode_char;}

@header {
def html_space_transformer(node):

    for child in node.children:
        html_space_transformer(child)

    if isinstance(node, UnparserRule):
        new_children = []
        for child in node.children:
            new_children.append(child)
            if child.name == 'htmlTagName' and child.right_sibling and child.right_sibling.name == 'htmlAttribute' \
                    or child.name == 'htmlAttribute' \
                    or isinstance(child, UnlexerRule) and child.src and child.src.endswith(('<script', '<style', '<?xml')):
                new_children.append(UnlexerRule(src=' '))
        node.children = new_children

    return node

}

@parser::member {
def endOfHtmlElement(self):
    pass

}

htmlDocument
    : (scriptlet | SEA_WS)* xml? (scriptlet | SEA_WS)* dtd? (scriptlet | SEA_WS)* htmlElements*
    ;

htmlElements
    : htmlMisc* htmlElement htmlMisc*
    ;

htmlElement
    : TAG_OPEN open_tag=htmlTagName htmlAttribute* TAG_CLOSE htmlContent TAG_OPEN TAG_SLASH htmlTagName {current.last_child = $open_tag.deepcopy()} TAG_CLOSE {self.endOfHtmlElement()}
    | TAG_OPEN open_tag=htmlTagName htmlAttribute* TAG_SLASH_CLOSE {self.endOfHtmlElement()}
    | TAG_OPEN open_tag=htmlTagName htmlAttribute* TAG_CLOSE {self.endOfHtmlElement()}
    | scriptlet
    | script
    | style
    ;

htmlContent
    : htmlChardata? ((htmlElement | xhtmlCDATA | htmlComment) htmlChardata?)*
    ;

htmlAttribute
    : attr_name=htmlAttributeName TAG_EQUALS htmlAttributeValue
    | attr_name=htmlAttributeName
    ;

htmlAttributeName
    : TAG_NAME
    ;

htmlAttributeValue
    : ATTVALUE_VALUE
    ;

htmlTagName
    : TAG_NAME
    ;

htmlChardata
    : HTML_TEXT
    | SEA_WS
    ;

htmlMisc
    : htmlComment
    | SEA_WS
    ;

htmlComment
    : HTML_COMMENT
    | HTML_CONDITIONAL_COMMENT
    ;

xhtmlCDATA
    : CDATA
    ;

dtd
    : DTD
    ;

xml
    : XML_DECLARATION
    ;

scriptlet
    : SCRIPTLET
    ;

script
    : SCRIPT_OPEN ( SCRIPT_BODY | SCRIPT_SHORT_BODY)
    ;

style
    : STYLE_OPEN ( STYLE_BODY | STYLE_SHORT_BODY)
    ;
